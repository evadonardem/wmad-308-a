import 'dart:convert';

import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';
  
  var userId = 5;
  var usersListEndpoint = '${apiBaseUrl}/users';
  var singleUserEndpoint = "$apiBaseUrl/users/$userId";
  var userAlbumListEndpoint = "$apiBaseUrl/users/$userId/albums";
  var userTodosListEndpoint = "$apiBaseUrl/users/$userId/todos";
  var userPostsListEndpoint = "$apiBaseUrl/users/$userId/posts";
    

  var responseUserList = await http.get(
    Uri.parse(usersListEndpoint),
  );

   var responseSingleUser = await http.get(
    Uri.parse(singleUserEndpoint),
  );

   var responseUserAlbumList = await http.get(
    Uri.parse(userAlbumListEndpoint),
  );

  var responseUserTodosList = await http.get(
    Uri.parse(userTodosListEndpoint),
  );

  var responseUserPostsList = await http.get(
    Uri.parse(userPostsListEndpoint),
  );

  var userJSON = jsonDecode(responseSingleUser.body);

  print("Listaan ng Fake Users");
  print(responseUserList.body);

 print("Albums ng ${userJSON['name']}");
  print(responseUserAlbumList.body);

 print("Todos ng ${userJSON['name']}");
  print(responseUserTodosList.body);

 print("Posts ng ${userJSON['name']}");
  print(responseUserPostsList.body);

}