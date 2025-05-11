import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared preferences demo',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MyHomePage(title: 'Shared preferences demo', isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.isDarkMode, required this.toggleTheme});

  final String title;
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  Future<void> _toggleSetting1(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting1 = value;
      prefs.setBool('setting1', _setting1);
    });
  }

  Future<void> _toggleSetting2(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting2 = value;
      prefs.setBool('setting2', _setting2);
    });
  }

  Future<void> _toggleSetting3(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _setting3 = value;
      prefs.setBool('setting3', _setting3);
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
            ToggleSwitch(
              minWidth: 90.0,
              minHeight: 70.0,
              initialLabelIndex: widget.isDarkMode ? 1 : 0,
              cornerRadius: 20.0,
              activeFgColor: Colors.white,
              inactiveBgColor: Colors.grey,
              inactiveFgColor: Colors.white,
              totalSwitches: 2,
              icons: [
                FontAwesomeIcons.lightbulb,
                FontAwesomeIcons.solidLightbulb,
              ],
              iconSize: 30.0,
              activeBgColors: [[Colors.black45, Colors.black26], [Colors.yellow, Colors.orange]],
              animate: true,
              curve: Curves.bounceInOut,
              onToggle: (index) {
                widget.toggleTheme(index == 1);
              },
            ),
            SwitchListTile(
              title: const Text('Setting 1'),
              value: _setting1,
              onChanged: _toggleSetting1,
              contentPadding: EdgeInsets.symmetric(horizontal: 50.0),
            ),
            SwitchListTile(
              title: const Text('Setting 2'),
              value: _setting2,
              onChanged: _toggleSetting2,
              contentPadding: EdgeInsets.symmetric(horizontal: 50.0),
            ),
            SwitchListTile(
              title: const Text('Setting 3'),
              value: _setting3,
              onChanged: _toggleSetting3,
              contentPadding: EdgeInsets.symmetric(horizontal: 50.0),
            ),
          ],
        ),
      ),
    );
  }
}
