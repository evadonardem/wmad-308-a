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
  bool _isSwitchOn = false; // For Dark Mode
  bool _setting1 = false;
  bool _setting2 = false;
  bool _setting3 = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load the initial switch state from persistent storage on start,
  /// or fallback to false if it doesn't exist.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitchOn = prefs.getBool('isSwitchOn') ?? false;
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  /// Save the switch state to persistent storage.
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Handle toggle of each setting.
  Future<void> _toggleSwitch(bool value, String settingKey) async {
    setState(() {
      if (settingKey == 'isSwitchOn') {
        _isSwitchOn = value;
      } else if (settingKey == 'setting1') {
        _setting1 = value;
      } else if (settingKey == 'setting2') {
        _setting2 = value;
      } else if (settingKey == 'setting3') {
        _setting3 = value;
      }
    });

    await _saveSetting(settingKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isSwitchOn ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(  // This will center everything in the middle of the screen
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,  // Center the children vertically
              crossAxisAlignment: CrossAxisAlignment.center,  // Center the children horizontally
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dark Mode', style: TextStyle(fontSize: 16)),
                    Switch(
                      value: _isSwitchOn,
                      onChanged: (bool value) {
                        _toggleSwitch(value, 'isSwitchOn');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Setting 1', style: TextStyle(fontSize: 16)),
                    Switch(
                      value: _setting1,
                      onChanged: (bool value) {
                        _toggleSwitch(value, 'setting1');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Setting 2', style: TextStyle(fontSize: 16)),
                    Switch(
                      value: _setting2,
                      onChanged: (bool value) {
                        _toggleSwitch(value, 'setting2');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Setting 3', style: TextStyle(fontSize: 16)),
                    Switch(
                      value: _setting3,
                      onChanged: (bool value) {
                        _toggleSwitch(value, 'setting3');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
