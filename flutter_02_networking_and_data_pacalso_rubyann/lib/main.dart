import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = "https://jsonplaceholder.typicode.com/";

  //fetch list of users
  var usersListEndpoint = '${apiBaseUrl}users';
  var responseUsers = await http.get(
    Uri.parse(usersListEndpoint),
  );
  print(responseUsers.body);

  var userId = 2;
  var showUserEndpoint = '${apiBaseUrl}users/${userId}';
  var responseUser = await http.get(
    Uri.parse(showUserEndpoint),
    );
  print(responseUser.body);

  //fetch albums of a perticular user
  var userAlbumsEndpoint = '${apiBaseUrl}users/${userId}/albums';
  var responseAlbums = await http.get(
    Uri.parse(userAlbumsEndpoint),
  );
  print(responseAlbums.body);

  //fetch todos of a particular user
  var userTodosEndpoint = '${apiBaseUrl}users/${userId}/todos';
  var responseTodos = await http.get(
    Uri.parse(userTodosEndpoint),
  );
  print(responseTodos.body);

  //fetch posts of a particular user
  var userPostsEndpoint = '${apiBaseUrl}users/${userId}/posts';
  var responsePosts = await http.get(
    Uri.parse(userPostsEndpoint),
  );
  print(responsePosts.body);
}
