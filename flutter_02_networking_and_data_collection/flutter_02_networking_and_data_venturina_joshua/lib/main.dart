import 'package:http/http.dart' as http;

Future<void> main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';

  
  var userListEndpoint = '${apiBaseUrl}/users';
  var response = await http.get(
    Uri.parse(userListEndpoint),
  );
  print('List of scammers:');
  print(response.body);

  var userId = 10;
  var singleUserListEndpoint = '${apiBaseUrl}/users/${userId}';
  var responseSingleUser = await http.get(
    Uri.parse(singleUserListEndpoint),
  );
  print('Detail of scammer:');
  print(responseSingleUser.body);

  var albumsEndpoint = '$apiBaseUrl/albums?userId=$userId';
  var responseAlbums = await http.get(Uri.parse(albumsEndpoint));
  print('Mga album ng scammer $userId:');
  print(responseAlbums.body);

  var todosEndpoint = '$apiBaseUrl/todos?userId=$userId';
  var responseTodos = await http.get(Uri.parse(todosEndpoint));
  print('Mga todo ng scammer $userId:');
  print(responseTodos.body);

   var postsEndpoint = '$apiBaseUrl/posts?userId=$userId';
  var responsePosts = await http.get(Uri.parse(postsEndpoint));
  print('Mga post ng scammer $userId:');
  print(responsePosts.body);
}

