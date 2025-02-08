import 'package:http/http.dart' as http;

void main() async {
  var apiBaseurl = 'https://jsonplaceholder.typicode.com';

  var usersListEndpoint = '${apiBaseurl}/users';
  var responseUsersList = await http.get(
    Uri.parse(usersListEndpoint)
  ); 
  print('List of fake users:');
  print(responseUsersList.body);

  var userId = 9;
  var userEndpoint = '${apiBaseurl}/users/$userId';
  var responseSingleUser = await http.get(
    Uri.parse(userEndpoint)
  );
  print('Detail of the fake user: $userId');
  print(responseSingleUser.body);

  var albumsEndpoint = '${apiBaseurl}/users/$userId/albums';
  var responseAlbums = await http.get(Uri.parse(albumsEndpoint));
  print('Albums for user $userId:');
  print(responseAlbums.body);

  var todosEndpoint = '${apiBaseurl}/users/$userId/todos';
  var responseTodos = await http.get(Uri.parse(todosEndpoint));
  print('Todos for user $userId:');
  print(responseTodos.body);

  var postsEndpoint = '${apiBaseurl}/users/$userId/posts';
  var responsePosts = await http.get(Uri.parse(postsEndpoint));
  print('Posts for user $userId:');
  print(responsePosts.body);
}