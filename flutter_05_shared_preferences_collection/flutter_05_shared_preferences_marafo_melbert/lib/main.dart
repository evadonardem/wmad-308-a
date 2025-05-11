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
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(key, value);
      if (key == 'darkMode') {
        _isDarkMode = value;
      } else if (key == 'setting1') {
        _setting1 = value;
      } else if (key == 'setting2') {
        _setting2 = value;
      } else if (key == 'setting3') {
        _setting3 = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Preferences Demo',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Shared Preferences Demo')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Setting 1'),
                Switch(
                  value: _setting1,
                  onChanged: (value) => _saveSetting('setting1', value),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Setting 2'),
                Switch(
                  value: _setting2,
                  onChanged: (value) => _saveSetting('setting2', value),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Setting 3'),
                Switch(
                  value: _setting3,
                  onChanged: (value) => _saveSetting('setting3', value),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Dark Mode'),
                Switch(
                  value: _isDarkMode,
                  onChanged: (value) => _saveSetting('darkMode', value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
