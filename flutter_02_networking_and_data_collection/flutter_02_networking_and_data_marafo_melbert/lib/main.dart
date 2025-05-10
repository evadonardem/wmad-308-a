import 'dart:convert';

import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = "https://jsonplaceholder.typicode.com";
  var quoteGeneratorApi = "https://nxttt.vercel.app/api/generateQuote";

  var userId = 8;
  var usersListEndpoint = "$apiBaseUrl/users";
  var singleUserEndpoint = "$apiBaseUrl/users/$userId";
  var userAlbumsListEndpoint = "$apiBaseUrl/users/$userId/albums";
  var userTodosListEndpoint = "$apiBaseUrl/users/$userId/todos";
  var userPostsListEndpoint = "$apiBaseUrl/users/$userId/posts";
  
  var responseUsersList = await http.get(
    Uri.parse(usersListEndpoint),
  );
  var responseSingleUser = await http.get(
    Uri.parse(singleUserEndpoint),
  );
  var responseUserAlbumsList = await http.get(
    Uri.parse(userAlbumsListEndpoint),
  );
  var responseUserTodosList = await http.get(
    Uri.parse(userTodosListEndpoint),
  );
  var responseUserPostsList = await http.get(
    Uri.parse(userPostsListEndpoint),
  );
  var responseQuote = await http.get(
    Uri.parse(quoteGeneratorApi),
  );

  var userJSON = jsonDecode(responseSingleUser.body);

  print("Listaan ti nagutang");
  print(responseUsersList.body);

  print("Nagutang ni ${userJSON['name']}");
  print(responseSingleUser.body);

  print("Albums ni ${userJSON['name']}");
  print(responseUserAlbumsList.body);
  
  print("Todos ni ${userJSON['name']}");
  print(responseUserTodosList.body);

  print("Posts ni ${userJSON['name']}");
  print(responseUserPostsList.body);

  var quoteJSON = jsonDecode(responseQuote.body);
  
  print("BONUS, Here is a quote for you");
  print(quoteJSON["quote"]);
}