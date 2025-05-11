import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.light);

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeMode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _toggleThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    _themeMode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Shared preferences demo Dark Mode',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: MyHomePage(
            title: 'Dark Mode',
            onToggleTheme: _toggleThemeMode,
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.onToggleTheme});

  final String title;
  final ValueChanged<bool> onToggleTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  Future<void> _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      switch (key) {
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
      prefs.setBool(key, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dark Mode:'),
            Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                widget.onToggleTheme(value);
              },
            ),
            const SizedBox(height: 20),
            const Text('Setting 1:'),
            Switch(
              value: _setting1,
              onChanged: (value) {
                _toggleSetting('setting1', value);
              },
            ),
            const SizedBox(height: 20),
            const Text('Setting 2:'),
            Switch(
              value: _setting2,
              onChanged: (value) {
                _toggleSetting('setting2', value);
              },
            ),
            const SizedBox(height: 20),
            const Text('Setting 3:'),
            Switch(
              value: _setting3,
              onChanged: (value) {
                _toggleSetting('setting3', value);
              },
            ),
          ],
        ),
      ),
    );
  }
}


