import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Preferences Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(title: 'Shared Preferences Demo'),
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
  int _counter = 0;
  bool _isDarkMode = false;
  bool _setting1 = false;
  bool _setting2 = false;
  bool _setting3 = false;

  @override
  void initState() {
    super.initState();
    _loadCounter();
    _loadSettings();
  }

  // Load the counter value and settings from persistent storage
  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('counter') ?? 0;
    });
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

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setBool('setting1', _setting1);
    await prefs.setBool('setting2', _setting2);
    await prefs.setBool('setting3', _setting3);
  }

  Future<void> _incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter++;
    });
    await prefs.setInt('counter', _counter);
  }

  // Toggle settings
  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveSettings();
  }

  void _toggleSetting1(bool value) {
    setState(() {
      _setting1 = value;
    });
    _saveSettings();
  }

  void _toggleSetting2(bool value) {
    setState(() {
      _setting2 = value;
    });
    _saveSettings();
  }

  void _toggleSetting3(bool value) {
    setState(() {
      _setting3 = value;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times: '),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
            ),
            SwitchListTile(
              title: const Text('Setting 1'),
              value: _setting1,
              onChanged: _toggleSetting1,
            ),
            SwitchListTile(
              title: const Text('Setting 2'),
              value: _setting2,
              onChanged: _toggleSetting2,
            ),
            SwitchListTile(
              title: const Text('Setting 3'),
              value: _setting3,
              onChanged: _toggleSetting3,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
