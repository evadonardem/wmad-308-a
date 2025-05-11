import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Shared preferences demo',
      home: MyHomePage(title: 'Shared preferences demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _darkMode = false;
  bool _setting1 = false;
  bool _setting2 = false;
  bool _setting3 = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  Future<void> _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(key, value);
      switch (key) {
        case 'darkMode':
          _darkMode = value;
          break;
        case 'setting1':
          _setting1 = value;
          break;
        case 'setting2':
          _setting2 = value;
          break;
        case 'setting3':
          _setting3 = value;
          break;
      }
    });
  }

  Color _getBackgroundColor() {
    if (_darkMode) return Colors.black;
    if (_setting1) return const Color.fromARGB(255, 6, 75, 9);
    if (_setting2) return const Color.fromARGB(255, 16, 4, 59);
    if (_setting3) return const Color.fromARGB(255, 12, 226, 226);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        color: _getBackgroundColor(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SwitchListTile(
                title: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto', // Adjust this to your preferred font
                    ),
                  ),
                ),
                value: _darkMode,
                onChanged: (bool value) {
                  _toggleSetting('darkMode', value);
                },
              ),
              if (_darkMode)
                Text(
                  'Dark Mode is ON',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              SwitchListTile(
                title: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Setting 1',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                value: _setting1,
                onChanged: (bool value) {
                  _toggleSetting('setting1', value);
                },
              ),
              if (_setting1)
                Text(
                  'Setting 1 is ON',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              SwitchListTile(
                title: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Setting 2',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                value: _setting2,
                onChanged: (bool value) {
                  _toggleSetting('setting2', value);
                },
              ),
              if (_setting2)
                Text(
                  'Setting 2 is ON',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              SwitchListTile(
                title: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Setting 3',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                value: _setting3,
                onChanged: (bool value) {
                  _toggleSetting('setting3', value);
                },
              ),
              if (_setting3)
                Text(
                  'Setting 3 is ON',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
