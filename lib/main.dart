
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_setup_screen.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

void main() {
  runApp(const ProveItApp());
}

class ProveItApp extends StatefulWidget {
  const ProveItApp({super.key});

  @override
  State<ProveItApp> createState() => _ProveItAppState();
}

class _ProveItAppState extends State<ProveItApp> {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  String _language = 'de';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final savedLanguage = await _prefs.getString('language');

    if (!mounted) return;

    setState(() {
      _language = savedLanguage == 'en' ? 'en' : 'de';
    });
  }

  Future<void> _changeLanguage(String language) async {
    setState(() {
      _language = language;
    });

    await _prefs.setString('language', language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PROVE IT!',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF171124),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB388FF),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(
        language: _language,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}                                                                                                                                   

class HomeScreen extends StatelessWidget {
  final String language;
  final ValueChanged<String> onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  bool get isGerman => language == 'de';

  void _openGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GameSetupScreen(),
      ),
    );
  }

  void _openPlayers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayerScreen(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          language: language,
          onLanguageChanged: onLanguageChanged,
        ),
      ),
    );
  }

  // Icon und Text werden zusammen horizontal zentriert
  // und für eine optisch mittige Position leicht
  // nach unten verschoben.
  Widget _imageButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool dark = false,
  }) {
    final color = dark
        ? const Color(0xFF241033)
        : const Color(0xFFE9DBFF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(70),
        child: SizedBox.expand(
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, 16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 50,
                        color: color,
                      ),

                      const SizedBox(width: 22),

                      Text(
                        text,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 49,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140C22),
      body: SizedBox.expand(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 941,
              height: 1672,
              child: Stack(
                children: [
                  // Hintergrundbild
                  Positioned.fill(
                    child: Image.asset(
                      'assets/prove_it_background.png',
                      fit: BoxFit.fill,
                    ),
                  ),

                  // Slogan
                  Positioned(
                    left: 80,
                    top: 835,
                    width: 781,
                    height: 125,
                    child: Center(
                      child: Text(
                        isGerman
                            ? 'Eine Antwort. Alle behaupten, '
                              'sie wäre von ihnen.\n'
                              'Wer sagt die Wahrheit?'
                            : 'One answer. Everyone claims it.\n'
                              "Who's telling the truth?",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 34,
                          height: 1.3,
                          color: Color(0xFFE3D2F4),
                        ),
                      ),
                    ),
                  ),

                  // Spiel starten
                  Positioned(
                    left: 95,
                    top: 1040,
                    width: 750,
                    height: 145,
                    child: _imageButton(
                      text: isGerman
                          ? 'SPIEL STARTEN'
                          : 'START GAME',
                      icon: Icons.play_arrow_rounded,
                      dark: true,
                      onTap: () => _openGame(context),
                    ),
                  ),

                  // Spieler verwalten
                  Positioned(
                    left: 95,
                    top: 1235,
                    width: 750,
                    height: 125,
                    child: _imageButton(
                      text: isGerman
                          ? 'SPIELER VERWALTEN'
                          : 'MANAGE PLAYERS',
                      icon: Icons.people_rounded,
                      onTap: () => _openPlayers(context),
                    ),
                  ),

                  // Einstellungen
                  Positioned(
                    left: 95,
                    top: 1385,
                    width: 750,
                    height: 125,
                    child: _imageButton(
                      text: isGerman
                          ? 'EINSTELLUNGEN'
                          : 'SETTINGS',
                      icon: Icons.settings_rounded,
                      onTap: () => _openSettings(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
