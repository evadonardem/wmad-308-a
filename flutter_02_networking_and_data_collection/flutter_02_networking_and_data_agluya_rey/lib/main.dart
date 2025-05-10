import 'package:http/http.dart' as http;

void main() async {
  var apiBaseUrl = 'https://jsonplaceholder.typicode.com/';

    var userListEndpoint = '${apiBaseUrl}users';
    var response = await http.get(
      Uri.parse(
        userListEndpoint
      )
    );

    print('Listahan ng mga user');
    print('Users: ${response.body}');

    var userId = 1;
    var singleUserEndpoint = '${apiBaseUrl}/users/${userId}';
    var responseSingleUser = await http.get(
      Uri.parse(
        singleUserEndpoint
      )
    );

    print('Detalye ng faker user ${userId}:');
    print('User Details: ${responseSingleUser.body}');


    //Fetch Todos
    var singleUserTodosEndpoint = '${apiBaseUrl}/users/${userId}/todos';
    var responseSingleUserTodos = await http.get(
      Uri.parse(
        singleUserTodosEndpoint
      )
    );

    print('Detalye ng faker user ${userId} Todos');
    print(responseSingleUserTodos.body);

    //Fetch Album
    var singleUserAlbumEndpoint = '${apiBaseUrl}/users/${userId}/albums';
    var responseSingleUserAlbum = await http.get(
      Uri.parse(
        singleUserAlbumEndpoint
      )
    );

    print('Detalye ng faker user ${userId} Album');
    print(responseSingleUserAlbum.body);

    //Fetch post
    var singleUserPostsEndpoint = '${apiBaseUrl}/users/${userId}/posts';
    var responseSingleUserPosts = await http.get(
      Uri.parse(
        singleUserPostsEndpoint
      )
    );

    print('Detalye ng faker user ${userId} Posts');
    print(responseSingleUserPosts.body);

}