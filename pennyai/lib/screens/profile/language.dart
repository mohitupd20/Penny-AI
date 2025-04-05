import 'package:flutter/material.dart';

class LanguagePreferenceScreen extends StatefulWidget {
  const LanguagePreferenceScreen({super.key});

  @override
  _LanguagePreferenceScreenState createState() => _LanguagePreferenceScreenState();
}

class _LanguagePreferenceScreenState extends State<LanguagePreferenceScreen> {
  final Map<String, String> _indianLanguages = {
    'hi-IN': 'Hindi',
    'bn-IN': 'Bengali',
    'kn-IN': 'Kannada',
    'ml-IN': 'Malayalam',
    'mr-IN': 'Marathi',
    'od-IN': 'Odia',
    'pa-IN': 'Punjabi',
    'ta-IN': 'Tamil',
    'te-IN': 'Telugu',
    'gu-IN': 'Gujarati',
    'en-IN': 'English'
  };

  String _selectedLanguage = 'en-IN';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Preferences'),
        backgroundColor: const Color(0xFF5E72E4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Your Preferred Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5E72E4),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF5E72E4), width: 2),
                ),
              ),
              items: _indianLanguages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveLanguagePreference,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E72E4),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Save Language Preference',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveLanguagePreference() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language set to ${_indianLanguages[_selectedLanguage]}'),
        backgroundColor: const Color(0xFF5E72E4),
      ),
    );
    // Here you would typically save the language preference
    // to a persistent storage or app settings
  }
}