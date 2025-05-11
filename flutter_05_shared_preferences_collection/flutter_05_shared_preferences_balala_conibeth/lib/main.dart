import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Dark Mode & Settings Toggle',
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
  bool _isDarkMode = false; // Default theme is light mode
  bool _setting1 = false;
  bool _setting2 = false;
  bool _setting3 = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved preferences from SharedPreferences
  }

  // Load the theme and settings preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _setting1 = prefs.getBool('setting1') ?? false;
      _setting2 = prefs.getBool('setting2') ?? false;
      _setting3 = prefs.getBool('setting3') ?? false;
    });
  }

  // Save the theme and settings preferences to SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('setting1', _setting1);
    await prefs.setBool('setting2', _setting2);
    await prefs.setBool('setting3', _setting3);
  }

  // Toggle the dark mode and save the preference
  Future<void> _toggleTheme(bool isDarkMode) async {
    setState(() {
      _isDarkMode = isDarkMode;
    });
    _savePreferences();
  }

  // Toggle settings and save their states
  Future<void> _toggleSetting(int settingNumber, bool value) async {
    setState(() {
      if (settingNumber == 1) {
        _setting1 = value;
      } else if (settingNumber == 2) {
        _setting2 = value;
      } else if (settingNumber == 3) {
        _setting3 = value;
      }
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light, // Switch theme mode based on the value
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blueAccent, colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orangeAccent),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.grey[850], colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.tealAccent),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dark Mode & Settings Toggle',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          backgroundColor: _isDarkMode ? Colors.black : const Color.fromARGB(255, 8, 89, 228),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400), // Restrict max width
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Enable Dark Mode ?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8),
                      ],
                    ),
                    child: SwitchListTile(
                      activeColor: const Color.fromARGB(255, 48, 240, 105),
                      inactiveThumbColor: Colors.grey,
                      title: Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      value: _isDarkMode,
                      onChanged: (bool value) {
                        _toggleTheme(value); // Toggle dark mode
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Settings switches (Setting1, Setting2, Setting3)
                  _buildSettingSwitch('Setting 1', _setting1, 1),
                  _buildSettingSwitch('Setting 2', _setting2, 2),
                  _buildSettingSwitch('Setting 3', _setting3, 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A helper method to create the switch tiles for settings
  Widget _buildSettingSwitch(String title, bool value, int settingNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8),
          ],
        ),
        child: SwitchListTile(
          activeColor: const Color.fromARGB(255, 5, 233, 43),
          inactiveThumbColor: Colors.grey,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          value: value,
          onChanged: (bool newValue) {
            _toggleSetting(settingNumber, newValue); // Toggle the setting value
          },
        ),
      ),
    );
  }
}