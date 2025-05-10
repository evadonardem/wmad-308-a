import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final setting1 = prefs.getBool('setting1') ?? false;
  final setting2 = prefs.getBool('setting2') ?? false;
  final setting3 = prefs.getBool('setting3') ?? false;
  runApp(MyApp(isDarkMode: isDarkMode, setting1: setting1, setting2: setting2, setting3: setting3));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final bool setting1;
  final bool setting2;
  final bool setting3;
  const MyApp({super.key, required this.isDarkMode, required this.setting1, required this.setting2, required this.setting3});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;
  late bool _setting1;
  late bool _setting2;
  late bool _setting3;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _setting1 = widget.setting1;
    _setting2 = widget.setting2;
    _setting3 = widget.setting3;
  }

  void _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(key, value);
      if (key == 'isDarkMode') _isDarkMode = value;
      if (key == 'setting1') _setting1 = value;
      if (key == 'setting2') _setting2 = value;
      if (key == 'setting3') _setting3 = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Preferences Demo',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MyHomePage(
        title: 'Shared Preferences Demo',
        isDarkMode: _isDarkMode,
        setting1: _setting1,
        setting2: _setting2,
        setting3: _setting3,
        toggleSetting: _toggleSetting,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final bool isDarkMode;
  final bool setting1;
  final bool setting2;
  final bool setting3;
  final Function(String, bool) toggleSetting;

  const MyHomePage({super.key, required this.title, required this.isDarkMode, required this.setting1, required this.setting2, required this.setting3, required this.toggleSetting});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('counter') ?? 0;
    });
  }

  Future<void> _incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = (prefs.getInt('counter') ?? 0) + 1;
      prefs.setInt('counter', _counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: widget.isDarkMode,
              onChanged: (value) => widget.toggleSetting('isDarkMode', value),
            ),
            SwitchListTile(
              title: const Text('Setting 1'),
              value: widget.setting1,
              onChanged: (value) => widget.toggleSetting('setting1', value),
            ),
            SwitchListTile(
              title: const Text('Setting 2'),
              value: widget.setting2,
              onChanged: (value) => widget.toggleSetting('setting2', value),
            ),
            SwitchListTile(
              title: const Text('Setting 3'),
              value: widget.setting3,
              onChanged: (value) => widget.toggleSetting('setting3', value),
            ),
            const SizedBox(height: 20),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
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