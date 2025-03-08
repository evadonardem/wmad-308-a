import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  bool _setting1 = false;
  bool _setting2 = false;
  bool _setting3 = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  Future<void> _togglePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(key, value);
      if (key == 'darkMode') _isDarkMode = value;
      if (key == 'setting1') _setting1 = value;
      if (key == 'setting2') _setting2 = value;
      if (key == 'setting3') _setting3 = value;
    });
  }

  Color _getBackgroundColor() {
    if (_setting1) {
      return Colors.blueAccent;
    } else if (_setting2) {
      return Colors.greenAccent;
    } else if (_setting3) {
      return Colors.deepPurpleAccent;
    }
    return _isDarkMode ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings Demo',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MyHomePage(
        title: 'Settings',
        isDarkMode: _isDarkMode,
        setting1: _setting1,
        setting2: _setting2,
        setting3: _setting3,
        onPreferenceChanged: _togglePreference,
        backgroundColor: _getBackgroundColor(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  final bool isDarkMode;
  final bool setting1;
  final bool setting2;
  final bool setting3;
  final Function(String, bool) onPreferenceChanged;
  final Color backgroundColor;

  const MyHomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.setting1,
    required this.setting2,
    required this.setting3,
    required this.onPreferenceChanged,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        color: backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Toggle Dark Mode:'),
              Switch(
                value: isDarkMode,
                onChanged: (value) => onPreferenceChanged('darkMode', value),
              ),
              const Text('Setting 1 (blueAccent Background):'),
              Switch(
                value: setting1,
                onChanged: (value) => onPreferenceChanged('setting1', value),
              ),
              const Text('Setting 2 (greenAccent Background):'),
              Switch(
                value: setting2,
                onChanged: (value) => onPreferenceChanged('setting2', value),
              ),
              const Text('Setting 3 (deepPurpleAccent Background):'),
              Switch(
                value: setting3,
                onChanged: (value) => onPreferenceChanged('setting3', value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
