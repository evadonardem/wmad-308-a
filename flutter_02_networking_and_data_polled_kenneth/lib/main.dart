import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';

  var usersListEndpoint = '${apiBaseUrl}/users';
  var response = await http.get(
    Uri.parse(usersListEndpoint),
  );
  print('Listahan nang fake users:');
  print(response.body);

  var userId = 1;
  var singleUserEndpoint = '${apiBaseUrl}/users/${userId}';
  var responseSingleUser = await http.get(
    Uri.parse(singleUserEndpoint),
  );
  print('Detalye nang fake user $userId:');
  print(responseSingleUser.body);

  // Fetch albums of the user
  var userAlbumsEndpoint = '${apiBaseUrl}/users/${userId}/albums';
  var responseUserAlbums = await http.get(
    Uri.parse(userAlbumsEndpoint),
  );
  print('Albums nang fake user $userId:');
  print(responseUserAlbums.body);

  // Fetch todos of the user
  var userTodosEndpoint = '${apiBaseUrl}/users/${userId}/todos';
  var responseUserTodos = await http.get(
    Uri.parse(userTodosEndpoint),
  );
  print('Todos nang fake user $userId:');
  print(responseUserTodos.body);

  // Fetch posts of the user
  var userPostsEndpoint = '${apiBaseUrl}/users/${userId}/posts';
  var responseUserPosts = await http.get(
    Uri.parse(userPostsEndpoint),
  );
  print('Posts nang fake user $userId:');
  print(responseUserPosts.body);
}