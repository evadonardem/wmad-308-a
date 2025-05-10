import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl ='https://jsonplaceholder.typicode.com';

  var usersListEndpoint = '${apiBaseUrl}/users';
  var response = await http.get(
    Uri.parse(usersListEndpoint),
  );
  print('Detail one of fake Users');
  print(response.body);

  var userId = 9;
  var singleUserEndpoint = '${apiBaseUrl}/users/$userId';
  var responseSingleUser = await http.get(
    Uri.parse(singleUserEndpoint),
  );

    print('List of fake Users ${userId}:');
  print(responseSingleUser.body);

   var userAlbumsEndpoint = '$apiBaseUrl/users/$userId/albums';
  var responseAlbums = await http.get(Uri.parse(userAlbumsEndpoint));

    print('\nAlbums of User $userId:');
  print(responseAlbums.body);

  var userTodosEndpoint = '$apiBaseUrl/users/$userId/todos';
  var responseTodos = await http.get(Uri.parse(userTodosEndpoint));

    print('\nTodos of User $userId:');
  print(responseTodos.body);

  var userPostsEndpoint = '$apiBaseUrl/users/$userId/posts';
  var responsePosts = await http.get(Uri.parse(userPostsEndpoint));

    print('\nPosts of User $userId:');
  print(responsePosts.body);

}
// fetch albums from a particular user
// fetch todos from a particular user
// fetch posts from a particular user