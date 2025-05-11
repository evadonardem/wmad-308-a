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

  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  // Save preferences to SharedPreferences
  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  Future<void> _toggleSetting1() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting1 = !_setting1;
      prefs.setBool('setting1', _setting1);
    });
  }

  Future<void> _toggleSetting2() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting2 = !_setting2;
      prefs.setBool('setting2', _setting2);
    });
  }

  Future<void> _toggleSetting3() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting3 = !_setting3;
      prefs.setBool('setting3', _setting3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings Demo',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: SettingsPage(
        toggleDarkMode: _toggleDarkMode,
        isDarkMode: _isDarkMode,
        toggleSetting1: _toggleSetting1,
        setting1: _setting1,
        toggleSetting2: _toggleSetting2,
        setting2: _setting2,
        toggleSetting3: _toggleSetting3,
        setting3: _setting3,
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;
  final VoidCallback toggleSetting1;
  final bool setting1;
  final VoidCallback toggleSetting2;
  final bool setting2;
  final VoidCallback toggleSetting3;
  final bool setting3;

  const SettingsPage({
    Key? key,
    required this.toggleDarkMode,
    required this.isDarkMode,
    required this.toggleSetting1,
    required this.setting1,
    required this.toggleSetting2,
    required this.setting2,
    required this.toggleSetting3,
    required this.setting3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Container(
          width: 300, // Set the width of the container
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // Background color for the container
            borderRadius: BorderRadius.circular(12), // Rounded corners
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ], // Add shadow for better elevation effect
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Vertically center the content
            crossAxisAlignment: CrossAxisAlignment.start, // Align items to the left
            children: [
              // Dark Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark Mode'),
                  Switch(
                    value: isDarkMode,
                    onChanged: (value) => toggleDarkMode(),
                  ),
                ],
              ),
              const Divider(),

              // Setting 1
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Setting 1'),
                  Switch(
                    value: setting1,
                    onChanged: (value) => toggleSetting1(),
                  ),
                ],
              ),
              const Divider(),

              // Setting 2
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Setting 2'),
                  Switch(
                    value: setting2,
                    onChanged: (value) => toggleSetting2(),
                  ),
                ],
              ),
              const Divider(),

              // Setting 3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Setting 3'),
                  Switch(
                    value: setting3,
                    onChanged: (value) => toggleSetting3(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
