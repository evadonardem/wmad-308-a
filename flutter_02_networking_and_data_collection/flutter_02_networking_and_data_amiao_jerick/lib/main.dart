import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com';

  // Fetch the list of users
  var userListEndPoint = '${apiBaseUrl}/users';
  var responseUserslist = await http.get(
    Uri.parse(userListEndPoint),
  );

  print('Listahan ng mga fake users:');
  print(responseUserslist.body);

  var userId = 9;
  
  // Fetch the details of a single user
  var singleUserEndPoint = '${apiBaseUrl}/users/$userId';
  var responseUserEndPoint = await http.get(
    Uri.parse(singleUserEndPoint),
  );
  print('Detalye ng mga fake user $userId:');
  print(responseUserEndPoint.body);

  // Fetch the todos of a user
  var userTodoEndPoint = '${apiBaseUrl}/users/$userId/todos';
  var responseUserTodoEndPoint = await http.get(
    Uri.parse(userTodoEndPoint),
  );
  print('Todos ng fake user $userId:');
  print(responseUserTodoEndPoint.body);

  // Fetch the albums of a user
  var userAlbumEndPoint = '${apiBaseUrl}/users/$userId/albums';
  var responseUserAlbumEndPoint = await http.get(
    Uri.parse(userAlbumEndPoint),
  );
  print('Albums ng fake user $userId:');
  print(responseUserAlbumEndPoint.body);

  // Fetch the posts of a user
  var userPostEndPoint = '${apiBaseUrl}/users/$userId/posts';
  var responseUserPostEndPoint = await http.get(
    Uri.parse(userPostEndPoint),
  );
  print('Mga post ng fake user $userId:');
  print(responseUserPostEndPoint.body);
}
