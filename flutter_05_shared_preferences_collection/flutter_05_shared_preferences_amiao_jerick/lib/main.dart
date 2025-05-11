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

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Preferences Demo',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MyHomePage(title: 'Shared Preferences Demo', onThemeChanged: _toggleDarkMode),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.onThemeChanged});

  final String title;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _switchValue1 = false;
  bool _switchValue2 = false;
  bool _switchValue3 = false;

  @override
  void initState() {
    super.initState();
    _loadSwitches();
  }

  Future<void> _loadSwitches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _switchValue1 = prefs.getBool('switch1') ?? false;
      _switchValue2 = prefs.getBool('switch2') ?? false;
      _switchValue3 = prefs.getBool('switch3') ?? false;
    });
  }

  Future<void> _saveSwitchValue(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged, String key) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        Switch(
          value: value,
          onChanged: (newValue) {
            setState(() {
              onChanged(newValue);
              _saveSwitchValue(key, newValue);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSwitch('Dark Mode', Theme.of(context).brightness == Brightness.dark, widget.onThemeChanged, 'isDarkMode'),
                  _buildSwitch('Switch 1', _switchValue1, (value) => setState(() => _switchValue1 = value), 'switch1'),
                  _buildSwitch('Switch 2', _switchValue2, (value) => setState(() => _switchValue2 = value), 'switch2'),
                  _buildSwitch('Switch 3', _switchValue3, (value) => setState(() => _switchValue3 = value), 'switch3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}