import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  bool setting1 = prefs.getBool('setting1') ?? false;
  bool setting2 = prefs.getBool('setting2') ?? false;
  bool setting3 = prefs.getBool('setting3') ?? false;
  runApp(MyApp(isDarkMode: isDarkMode, setting1: setting1, setting2: setting2, setting3: setting3));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final bool setting1;
  final bool setting2;
  final bool setting3;

  MyApp({required this.isDarkMode, required this.setting1, required this.setting2, required this.setting3});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isDarkMode;
  late bool setting1;
  late bool setting2;
  late bool setting3;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    setting1 = widget.setting1;
    setting2 = widget.setting2;
    setting3 = widget.setting3;
  }

  void toggleDarkMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode);
    });
  }

  void toggleSetting1() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      setting1 = !setting1;
      prefs.setBool('setting1', setting1);
    });
  }

  void toggleSetting2() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      setting2 = !setting2;
      prefs.setBool('setting2', setting2);
    });
  }

  void toggleSetting3() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      setting3 = !setting3;
      prefs.setBool('setting3', setting3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Settings Switches'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SwitchListTile(
                title: Text('Dark Mode'),
                value: isDarkMode,
                onChanged: (value) {
                  toggleDarkMode();
                },
              ),
              SwitchListTile(
                title: Text('Setting1'),
                value: setting1,
                onChanged: (value) {
                  toggleSetting1();
                },
              ),
              SwitchListTile(
                title: Text('Setting2'),
                value: setting2,
                onChanged: (value) {
                  toggleSetting2();
                },
              ),
              SwitchListTile(
                title: Text('Setting3'),
                value: setting3,
                onChanged: (value) {
                  toggleSetting3();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}