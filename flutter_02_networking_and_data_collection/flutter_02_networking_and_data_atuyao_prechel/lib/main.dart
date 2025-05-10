import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';
  
 
  var usersListEndpoint = '${apiBaseUrl}/users';
  var responseUserList = await http.get(Uri.parse(usersListEndpoint));

 
  print('ipakita ang detalye');
  print(responseUserList.body);

  
  var userId = 9;
  var singleUserEndpoint = '${apiBaseUrl}/users/$userId';
  var responseSingleUser = await http.get(Uri.parse(singleUserEndpoint));

  print('to dos ni user');
  print(responseSingleUser.body);

  
  var usersAlbumEndpoint = '${apiBaseUrl}/users/1/albums';
  var responseAlbum = await http.get(Uri.parse(usersAlbumEndpoint));

 
  print('listahan ng mga fake user');
  print(responseAlbum.body);

  var usersPostEndpoint = '${apiBaseUrl}/users/1';
  var responsePost = await http.get(Uri.parse(usersAlbumEndpoint));

 
  print('listahan ng mga fake user');
  print(responsePost.body);

  var usersToDoEndpoint = '${apiBaseUrl}/users/1/todos';
  var responseTodo = await http.get(Uri.parse(usersAlbumEndpoint));

 
  print('to dos ni user');
  print(responseTodo.body);
}
