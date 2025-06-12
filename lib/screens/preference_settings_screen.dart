import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fasum/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceSettingsScreen extends StatefulWidget {
  const PreferenceSettingsScreen({super.key});

  @override
  _PreferenceSettingsScreenState createState() => _PreferenceSettingsScreenState();
}

class _PreferenceSettingsScreenState extends State<PreferenceSettingsScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Load the theme preference when the screen loads
  _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Save the theme preference when it changes
  _saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preference Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Dark Mode'),
              value: _isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  _isDarkMode = value;
                });
                _saveTheme(value);

                // Update the theme immediately by calling the provider
                Provider.of<ThemeProvider>(context, listen: false).setDarkMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
