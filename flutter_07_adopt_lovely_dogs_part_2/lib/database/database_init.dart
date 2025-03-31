import 'database_helper.dart';

Future<void> initDatabase() async {
  await DatabaseHelper.instance.database;
}