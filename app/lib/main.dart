import 'dart:convert';

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
  // int? counter;
  // Map? map;

// String socketUrl = 'wss://myservernew-rz235lxkgq-uc.a.run.app/ws';
  String socketUrl = 'ws://localhost:8080/sql';
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print(socketUrl);
    channel = WebSocketChannel.connect(Uri.parse(socketUrl));

    channel.stream.listen((data) {
      print(data);
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  _sendIncrementComand(name) async {
    Map<String, dynamic> data = {'name': name, 'action': 'addUser'};
    channel.sink.add(jsonEncode(data));
  }

  _printMap() {
    // print(map);
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
            Text(
              '?',
              style: Theme.of(context).textTheme.headline4,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _sendIncrementComand(nameController.text);
          _printMap();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
