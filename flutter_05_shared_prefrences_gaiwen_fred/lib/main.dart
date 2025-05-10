import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Settings Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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
    _loadSettings();
  }

  /// Load settings (dark mode and other settings) from persistent storage.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  /// Toggle dark mode and save the preference.
  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  /// Toggle setting1 and save the preference.
  Future<void> _toggleSetting1(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting1 = value;
      prefs.setBool('setting1', _setting1);
    });
  }

  /// Toggle setting2 and save the preference.
  Future<void> _toggleSetting2(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting2 = value;
      prefs.setBool('setting2', _setting2);
    });
  }

  /// Toggle setting3 and save the preference.
  Future<void> _toggleSetting3(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting3 = value;
      prefs.setBool('setting3', _setting3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Settings Demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dark Mode Setting
              ListTile(
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (bool value) {
                    _toggleDarkMode();
                  },
                ),
              ),
              const Divider(),

              // Setting 1
              ListTile(
                title: const Text('Setting 1'),
                trailing: Switch(
                  value: _setting1,
                  onChanged: (bool value) {
                    _toggleSetting1(value);
                  },
                ),
              ),
              const Divider(),

              // Setting 2
              ListTile(
                title: const Text('Setting 2'),
                trailing: Switch(
                  value: _setting2,
                  onChanged: (bool value) {
                    _toggleSetting2(value);
                  },
                ),
              ),
              const Divider(),

              // Setting 3
              ListTile(
                title: const Text('Setting 3'),
                trailing: Switch(
                  value: _setting3,
                  onChanged: (bool value) {
                    _toggleSetting3(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
