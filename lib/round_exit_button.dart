
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoundExitButton extends StatefulWidget {
  const RoundExitButton({super.key});

  @override
  State<RoundExitButton> createState() => _RoundExitButtonState();
}

class _RoundExitButtonState extends State<RoundExitButton> {
  bool _dialogOpen = false;

  Future<void> _confirmExit() async {
    if (_dialogOpen) return;

    _dialogOpen = true;

    final prefs = SharedPreferencesAsync();
    String language = 'de';

    try {
      language = await prefs.getString('language') ?? 'de';
    } catch (_) {
      language = 'de';
    }

    if (!mounted) return;

    final isGerman = language != 'en';

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF281A3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(
              color: Color(0xFF67438E),
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB585F9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isGerman
                      ? 'Runde abbrechen?'
                      : 'Quit round?',
                  style: const TextStyle(
                    color: Color(0xFFE5D1FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isGerman
                ? 'Wenn du die Runde abbrichst, '
                  'gehen alle aktuellen Antworten '
                  'und der Spielfortschritt verloren.\n\n'
                  'Möchtest du die Runde wirklich beenden?'
                : 'If you quit this round, '
                  'all current answers and progress '
                  'will be lost.\n\n'
                  'Are you sure you want to quit?',
            style: const TextStyle(
              color: Colors.white,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                isGerman ? 'WEITERSPIELEN' : 'KEEP PLAYING',
                style: const TextStyle(
                  color: Color(0xFFE5D1FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB585F9),
                foregroundColor: const Color(0xFF1D0D30),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                isGerman ? 'RUNDE BEENDEN' : 'QUIT ROUND',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    _dialogOpen = false;

    if (shouldExit == true) {
      // Alle Spielbildschirme schließen.
      // Zur vorhandenen Startseite zurückkehren.
      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Runde abbrechen / Quit round',
      icon: const Icon(
        Icons.close_rounded,
        color: Color(0xFFE5D1FF),
        size: 27,
      ),
      onPressed: _confirmExit,
    );
  }
}
