
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bluff_screen.dart';
import 'round_exit_button.dart';

class RoleRevealScreen extends StatefulWidget {
  final List<String> players;
  final int judgeCount;
  final String question;
  final Map<String, String> answers;

  const RoleRevealScreen({
    super.key,
    required this.players,
    required this.judgeCount,
    required this.question,
    required this.answers,
  });

  @override
  State<RoleRevealScreen> createState() =>
      _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  static const Color _background = Color(0xFF130D21);
  static const Color _cardColor = Color(0xFF281A3E);
  static const Color _accent = Color(0xFFB585F9);
  static const Color _lightPurple = Color(0xFFE5D1FF);
  static const Color _muted = Color(0xFFBBA9D0);

  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  late final List<String> _judges;
  late final List<String> _candidates;
  late final String _realOne;
  late final String _selectedAnswer;

  bool _showAnswer = false;
  bool _isLoading = true;
  String _language = 'de';

  bool get isGerman => _language == 'de';

  String _translate(String de, String en) {
    return isGerman ? de : en;
  }

  @override
  void initState() {
    super.initState();

    final random = Random();
    final shuffledPlayers =
        List<String>.from(widget.players)..shuffle(random);

    // Judges werden zufällig bestimmt.
    _judges = shuffledPlayers
        .take(widget.judgeCount)
        .toList();

    // Alle übrigen Spieler sind Verdächtige.
    _candidates = widget.players
        .where((name) => !_judges.contains(name))
        .toList();

    // Eine Person ist THE REAL ONE.
    _realOne = _candidates[
      random.nextInt(_candidates.length)
    ];

    // Nur diese Antwort wird später gezeigt.
    _selectedAnswer = widget.answers[_realOne]!;

    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final saved =
          await _prefs.getString('language');

      if (!mounted) return;

      setState(() {
        _language = saved == 'en' ? 'en' : 'de';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _language = 'de';
        _isLoading = false;
      });
    }
  }

  void _revealAnswer() {
    setState(() {
      _showAnswer = true;
    });
  }

  void _startBluffRound() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BluffScreen(
          question: widget.question,
          answer: _selectedAnswer,
          realOne: _realOne,
          judges: _judges,
          candidates: _candidates,
          players: widget.players,
          judgeCount: widget.judgeCount,
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF493267),
        ),
      ),
      child: child,
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: const Color(0xFF1D0D30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 25),
            const SizedBox(width: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigIcon(IconData icon) {
    return Container(
      width: 115,
      height: 115,
      decoration: BoxDecoration(
        color: const Color(0xFF392250),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF6A468D),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 65,
        color: _lightPurple,
      ),
    );
  }

  // ERSTER BILDSCHIRM: JUDGES
  Widget _judgesScreen() {
    final singleJudge = _judges.length == 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _bigIcon(Icons.gavel_rounded),

        const SizedBox(height: 28),

        Text(
          singleJudge
              ? 'THE JUDGE IS...'
              : 'THE JUDGES ARE...',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          _translate(
            singleJudge
                ? 'Der Judge wurde ausgelost!'
                : 'Die Judges wurden ausgelost!',
            singleJudge
                ? 'The judge has been selected!'
                : 'The judges have been selected!',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: _muted,
          ),
        ),

        const SizedBox(height: 26),

        _card(
          child: Column(
            children: [
              for (int i = 0; i < _judges.length; i++) ...[
                if (i > 0)
                  const Divider(
                    color: Color(0xFF5B4078),
                    height: 28,
                  ),

                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        color: Color(0xFF603E83),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: _lightPurple,
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        _judges[i].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: _lightPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        _card(
          child: Column(
            children: [
              const Icon(
                Icons.groups_rounded,
                color: _accent,
                size: 35,
              ),

              const SizedBox(height: 12),

              Text(
                _translate(
                  singleJudge
                      ? 'Finde heraus, wer die Wahrheit sagt!'
                      : 'Ihr seid ein Team!',
                  singleJudge
                      ? 'Find out who is telling the truth!'
                      : 'You are a team!',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _lightPurple,
                ),
              ),

              if (!singleJudge) ...[
                const SizedBox(height: 10),

                Text(
                  _translate(
                    'Findet gemeinsam heraus, '
                    'wer die Wahrheit sagt.',
                    'Work together to find out '
                    'who is telling the truth.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _muted,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),

        _primaryButton(
          label: _translate(
            'ANTWORT AUFDECKEN',
            'REVEAL ANSWER',
          ),
          icon: Icons.visibility_rounded,
          onPressed: _revealAnswer,
        ),
      ],
    );
  }

  // ZWEITER BILDSCHIRM: ANTWORT AUFDECKEN
  Widget _answerRevealScreen() {
    return Column(
      children: [
        _bigIcon(Icons.visibility_rounded),

        const SizedBox(height: 25),

        Text(
          _translate(
            'DIE ANTWORT',
            'THE ANSWER',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: _lightPurple,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          _translate(
            'Wem gehört diese Antwort wirklich?',
            'Who really wrote this answer?',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 24),

        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate(
                  'DIE FRAGE',
                  'THE QUESTION',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: _accent,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                widget.question,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3C2459),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _accent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 38,
                color: _accent,
              ),

              const SizedBox(height: 15),

              Text(
                _selectedAnswer,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        Text(
          _translate(
            'Alle Nicht-Judges behaupten, '
            'diese Antwort geschrieben zu haben.\n'
            'Nur eine Person sagt die Wahrheit!',
            'Every non-judge claims to have '
            'written this answer.\n'
            'Only one person is telling the truth!',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: _muted,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 25),

        _card(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: _accent,
                  ),

                  const SizedBox(width: 10),

                  Flexible(
                    child: Text(
                      _translate(
                        'DIE VERDÄCHTIGEN',
                        'THE SUSPECTS',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: _lightPurple,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _candidates.map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3268),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        _primaryButton(
          label: _translate(
            'BLUFFRUNDE STARTEN',
            'START BLUFF ROUND',
          ),
          icon: Icons.play_arrow_rounded,
          onPressed: _startBluffRound,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(
          child: CircularProgressIndicator(
            color: _accent,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _background,

        appBar: AppBar(
          backgroundColor: _background,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text(
            'PROVE IT!',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),

          // NEU: Runde oben rechts abbrechen.
          actions: const [
            RoundExitButton(),
          ],
        ),

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                22,
                20,
                22,
                35,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 550,
                ),
                child: _showAnswer
                    ? _answerRevealScreen()
                    : _judgesScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
