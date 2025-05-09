import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';

  var usersListEndpoint = '$apiBaseUrl/users';
  var responseUsersList = await http.get(Uri.parse(usersListEndpoint));

  print('Listahan nang mga fake users');
  print(responseUsersList.body);

  var userId = 9;
  var singleUserEndpoint = '$apiBaseUrl/users/$userId';
  var responseSingleUser = await http.get(Uri.parse(singleUserEndpoint));

  print('Detalye nang mga fake users $userId:');
  print(responseSingleUser.body);

  // Fetch albums for the specific user
  var albumsEndpoint = '$apiBaseUrl/albums?userId=$userId';
  var responseAlbums = await http.get(Uri.parse(albumsEndpoint));

  print('Mga album ng fake user $userId:');
  print(responseAlbums.body);

  // Fetch todos for the specific user
  var todosEndpoint = '$apiBaseUrl/todos?userId=$userId';
  var responseTodos = await http.get(Uri.parse(todosEndpoint));

  print('Mga todo ng fake user $userId:');
  print(responseTodos.body);

  // Fetch posts for the specific user
  var postsEndpoint = '$apiBaseUrl/posts?userId=$userId';
  var responsePosts = await http.get(Uri.parse(postsEndpoint));
  
  print('Mga post ng fake user $userId:');
  print(responsePosts.body);
}
