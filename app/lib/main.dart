import 'dart:async';
import 'dart:convert';

import 'package:dartservertest/userModel.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebSocketChannel channel;

// String socketUrl = 'wss://myservernew-rz235lxkgq-uc.a.run.app/ws';
  String socketUrl = 'ws://localhost:8080/sql';
  TextEditingController nameController = TextEditingController();
  var myStreamController = StreamController<bool>.broadcast();
  User user = User();
  List jsonData = [];
  List<User> listOfUsers = [];

  @override
  void initState() {
    super.initState();
    print(socketUrl);
    channel = WebSocketChannel.connect(Uri.parse(socketUrl));
    _buildUserStream();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  _buildUserStream() {
    channel.stream.listen((data) {
      setState(() {
        jsonData = json.decode(data);
        listOfUsers = jsonData.map((i) => User.fromJson(i)).toList();
      });
    });
  }

  _sendIncrementComand(name) async {
    Map<String, dynamic> data = {'name': name, 'action': 'addUser'};
    channel.sink.add(jsonEncode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              socketUrl,
            ),
            StreamBuilder(
                builder: ((context, snapshot) {
                  return Text(
                    '${listOfUsers.length}',
                    style: Theme.of(context).textTheme.headline4,
                  );
                }),
                stream: myStreamController.stream),
            SizedBox(
              height: 400,
              width: 400,
              child: ListView.builder(
                  itemCount: listOfUsers == null ? 0 : listOfUsers.length,
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return ListTile(
                        title: Text(listOfUsers == null
                            ? 'something coming '
                            : listOfUsers[index].name!));
                  }),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          onPressed: () {
            _sendIncrementComand(nameController.text);
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ]),
    );
  }
}
