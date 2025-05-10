import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';
  var userId = 9;  // specify the user ID you want to fetch data for

  // Fetch the list of users
  var usersListEndpoint = '${apiBaseUrl}/users';
  var response = await http.get(
    Uri.parse(usersListEndpoint),
  );
  print('Listahan ng Fake users:');
  print(response.body);

  // Fetch a specific user
  var singleUserEndpoint = '${apiBaseUrl}/users/${userId}';
  var responseSingleUser = await http.get(
    Uri.parse(singleUserEndpoint),
  );
  print('Detalye ng faker user $userId:');
  print(responseSingleUser.body);

  // Fetch albums from a specific user
  var albumsEndpoint = '${apiBaseUrl}/users/$userId/albums';
  var responseAlbums = await http.get(
    Uri.parse(albumsEndpoint),
  );
  print('Albums ng faker user $userId:');
  print(responseAlbums.body);

  // Fetch todos from a specific user
  var todosEndpoint = '${apiBaseUrl}/users/$userId/todos';
  var responseTodos = await http.get(
    Uri.parse(todosEndpoint),
  );
  print('Todos ng faker user $userId:');
  print(responseTodos.body);

  // Fetch posts from a specific user
  var postsEndpoint = '${apiBaseUrl}/users/$userId/posts';
  var responsePosts = await http.get(
    Uri.parse(postsEndpoint),
  );
  print('Posts ng faker user $userId:');
  print(responsePosts.body);
}
