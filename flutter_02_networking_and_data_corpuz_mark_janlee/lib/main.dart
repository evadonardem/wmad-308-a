import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';

  var usersListEndpoint = '${apiBaseUrl}/users';

  var response = await http.get(
    Uri.parse(usersListEndpoint),
  );
  print('Listahan nang fake users:');
  print(response.body);

  var userId = 6;
  var singleUserEndPoint = '${apiBaseUrl}/users/${userId}';
  var responseSingleUser = await http.get(
    Uri.parse(singleUserEndPoint),
  );

  print('Detalye ng fake user ${userId}');
  print(responseSingleUser.body);

// fetch albums from a particular user
  var singleUserAlbumEndPoint = '${apiBaseUrl}/users/${userId}/albums';
  var responseSingleUserAlbum = await http.get(
    Uri.parse(singleUserAlbumEndPoint),
  );
  print('Detalye ng fake user ${userId} ALBUMS');
  print(responseSingleUserAlbum.body);

// fetch todos " "
  var singleUserTodosEndPoint = '${apiBaseUrl}/users/${userId}/todos';
  var responseSingleUserTodos = await http.get(
    Uri.parse(singleUserTodosEndPoint),
  );
  print('Detalye ng fake user ${userId} TODOS');
  print(responseSingleUserTodos.body);

  // fetch post " "
  var singleUserPostsEndPoint = '${apiBaseUrl}/users/${userId}/posts';
  var responseSingleUserPosts = await http.get(
    Uri.parse(singleUserPostsEndPoint),
  );
  print('Detalye ng fake user ${userId} POSTS');
  print(responseSingleUserPosts.body);
}
