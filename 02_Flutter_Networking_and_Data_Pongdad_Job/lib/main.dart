import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com/';

  var userListEndpoint = '${apiBaseUrl}users';
  var responseUsers = await http.get(Uri.parse(userListEndpoint));
  print(responseUsers.body);

  var userID = 4; 
  var showUserEndpoint = '${apiBaseUrl}users/$userID';
  var responseUser = await http.get(Uri.parse(showUserEndpoint));
  print(responseUser.body);

  var albumsEndpoint = '${apiBaseUrl}users/$userID/albums';
  var responseAlbums = await http.get(Uri.parse(albumsEndpoint));
  print(responseAlbums.body);
 
  var todosEndpoint = '${apiBaseUrl}users/$userID/todos';
  var responseTodos = await http.get(Uri.parse(todosEndpoint));
  print(responseTodos.body);

  var postsEndpoint = '${apiBaseUrl}users/$userID/posts';
  var responsePosts = await http.get(Uri.parse(postsEndpoint));
  print(responsePosts.body);
}