import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UserPage(),
    );
  }
}

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';
  var userId = 1;
  Map<String, dynamic> userData = {};
  List<dynamic> userAlbums = [];
  List<dynamic> userTodos = [];
  List<dynamic> userPosts = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    var singleUserEndpoint = '${apiBaseUrl}/users/${userId}';
    var responseSingleUser = await http.get(
      Uri.parse(singleUserEndpoint),
    );
    var userAlbumsEndpoint = '${apiBaseUrl}/users/${userId}/albums';
    var responseUserAlbums = await http.get(
      Uri.parse(userAlbumsEndpoint),
    );
    var userTodosEndpoint = '${apiBaseUrl}/users/${userId}/todos';
    var responseUserTodos = await http.get(
      Uri.parse(userTodosEndpoint),
    );
    var userPostsEndpoint = '${apiBaseUrl}/users/${userId}/posts';
    var responseUserPosts = await http.get(
      Uri.parse(userPostsEndpoint),
    );

    setState(() {
      userData = json.decode(responseSingleUser.body);
      userAlbums = json.decode(responseUserAlbums.body);
      userTodos = json.decode(responseUserTodos.body);
      userPosts = json.decode(responseUserPosts.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalye nang fake user $userId:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(userData.toString()),
              SizedBox(height: 20),
              Text('Albums:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...userAlbums.map((album) => Text(album.toString())).toList(),
              SizedBox(height: 20),
              Text('Todos:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...userTodos.map((todo) => Text(todo.toString())).toList(),
              SizedBox(height: 20),
              Text('Posts:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...userPosts.map((post) => Text(post.toString())).toList(),
            ],
          ),
        ),
      ),
    );
  }
}