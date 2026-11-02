
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final String language;
  final ValueChanged<String> onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isGerman = language == 'de';

    return Scaffold(
      backgroundColor: const Color(0xFF171124),
      appBar: AppBar(
        title: Text(
          isGerman ? 'Einstellungen' : 'Settings',
        ),
        backgroundColor: const Color(0xFF171124),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text(
              isGerman
                  ? 'Sprache auswählen'
                  : 'Choose language',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              isGerman
                  ? 'In welcher Sprache möchtest du spielen?'
                  : 'Which language would you like to play in?',
              style: const TextStyle(
                color: Color(0xFFBDB1CE),
              ),
            ),

            const SizedBox(height: 30),

            // Moderne Flutter-Sprachauswahl
            RadioGroup<String>(
              groupValue: language,
              onChanged: (value) {
                if (value != null) {
                  onLanguageChanged(value);
                }
              },
              child: const Card(
                color: Color(0xFF30213F),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('🇩🇪 Deutsch'),
                      value: 'de',
                      activeColor: Color(0xFFB388FF),
                    ),

                    Divider(height: 1),

                    RadioListTile<String>(
                      title: Text('🇬🇧 English'),
                      value: 'en',
                      activeColor: Color(0xFFB388FF),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                const Icon(
                  Icons.save_outlined,
                  color: Color(0xFFB388FF),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    isGerman
                        ? 'Deine Auswahl wird automatisch gespeichert.'
                        : 'Your choice is saved automatically.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFBDB1CE),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
