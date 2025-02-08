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

}