import 'dart:convert';
import 'dart:io';
import 'package:mysql1/mysql1.dart';
import 'package:redis/redis.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

int _counterValue = 0;

//list of clients
final _client = <WebSocketChannel>[];

//redis server connection variables
late final RedisConnection conn;
late final Command command;

late final RedisConnection pubSubConn;
late final Command pubSubCommand;
late final PubSub pubSub;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/ws', webSocketHandler(_handler))
  ..get('/sql', webSocketHandler(_sqlHandler));

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void _sqlHandler(WebSocketChannel webSocket) {
  _client.add(webSocket);
  webSocket.stream.listen(
    (dynamic message) async {
      stdout.writeln('Message received: $message');
      print('this is the message: $message');
      var data = jsonDecode(message);
      print(data['name']);
      if (message != null && data['action'] == 'addUser') {
        //TODO: add user to database
        var settings = ConnectionSettings(
            host:
                'dart-dataserver-test.cr5cn3uj0ni0.us-east-1.rds.amazonaws.com',
            port: 3306,
            user: 'admin',
            password: '12345678',
            db: 'flutterdb');
        var connection = await MySqlConnection.connect(settings);
        print('connected');
        var result = await connection
            .query('insert into users (name) values (?)', [data['name']]);
        var results = await connection.query('select * from users');
        for (var row in results) {
          var map = {'id': row[0], 'name': row[1]};
          print(map['name']);
          for (var client in _client) {
            client.sink.add(json.encode(map));
          }
        }
      }
    },
    onDone: () {
      _client.remove(webSocket);
    },
  );
}

void _handler(WebSocketChannel webSocket) {
  _client.add(webSocket);
  //setting value in redis
  command.send_object(['GET', 'counter']).then((value) {
    webSocket.sink.add(value.toString());
  });
  //Checking for connection
  stdout.writeln('WebSocket connection established: $webSocket');
  webSocket.stream.listen((dynamic message) async {
    //taking logs from client
    stdout.writeln('Received message: $message');
    //checking the message from client
    if (message == 'increment') {
      final newVal = await command.send_object(['INCR', 'counter']);
      //Incrementing value to our local variable
      command.send_object(["Publish", "counterUpdate", "counter"]);
      // _counterValue++;
      //sending the value to client`s stream
      for (final client in _client) {
        client.sink.add(newVal.toString());
      }
    }
  }, onDone: () {
    _client.remove(webSocket);
  });
}

void main(List<String> args) async {
  //redis server connection
  conn = RedisConnection();
  command = await conn.connect('localhost', 6379);

  pubSubConn = RedisConnection();
  pubSubCommand = await pubSubConn.connect('localhost', 6379);
  pubSub = PubSub(pubSubCommand);
  pubSub.subscribe(['counterUpdate']);
  pubSub
      .getStream()
      .handleError((e) => print('error $e'))
      .listen((mesaage) async {
    print('message $mesaage');
    final newVal = await command.send_object(['Get', 'counter']);
    for (final client in _client) {
      client.sink.add(newVal.toString());
    }
  });
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
