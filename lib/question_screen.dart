
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'question_bank.dart';
import 'question_bank_en.dart';
import 'role_reveal_screen.dart';
import 'round_exit_button.dart';

class QuestionScreen extends StatefulWidget {
  final List<String> players;
  final int judgeCount;

  const QuestionScreen({
    super.key,
    required this.players,
    required this.judgeCount,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final TextEditingController _answerController =
      TextEditingController();

  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  static const Color _background = Color(0xFF130D21);
  static const Color _cardColor = Color(0xFF281A3E);
  static const Color _accent = Color(0xFFB585F9);
  static const Color _lightPurple = Color(0xFFE5D1FF);
  static const Color _muted = Color(0xFFBBA9D0);

  static const String _usedQuestionsKey =
      'prove_it_used_question_ids_v1';

  final Map<String, String> _answers = {};

  int _currentPlayerIndex = 0;
  int _questionIndex = 0;

  bool _isReady = false;
  bool _finished = false;
  bool _isLoading = true;

  String _language = 'de';
  String? _loadError;

  bool get isGerman => _language == 'de';

  String _translate(String de, String en) {
    return isGerman ? de : en;
  }

  String get _question {
    if (isGerman) {
      return QuestionBank.questions[_questionIndex];
    }

    return QuestionBankEn.questions[_questionIndex];
  }

  @override
  void initState() {
    super.initState();
    _initializeRound();
  }

  // Sprache laden und eine noch unbenutzte Frage auswählen.
  Future<void> _initializeRound() async {
    try {
      final totalQuestions = QuestionBank.questions.length;

      if (totalQuestions == 0 ||
          QuestionBankEn.questions.length != totalQuestions) {
        throw StateError(
          'Die deutsche und englische Fragenbank '
          'müssen gleich viele Fragen enthalten.',
        );
      }

      final savedLanguage =
          await _prefs.getString('language');

      final savedIds =
          await _prefs.getStringList(_usedQuestionsKey) ?? [];

      // Bereits verwendete Fragen einlesen.
      final usedIds = <int>{};

      for (final id in savedIds) {
        final parsedId = int.tryParse(id);

        if (parsedId != null &&
            parsedId >= 0 &&
            parsedId < totalQuestions) {
          usedIds.add(parsedId);
        }
      }

      // Wenn alle Fragen verwendet wurden,
      // startet automatisch ein neuer Durchlauf.
      if (usedIds.length >= totalQuestions) {
        usedIds.clear();
      }

      // Alle noch nicht verwendeten Fragen sammeln.
      final availableIds = <int>[];

      for (int i = 0; i < totalQuestions; i++) {
        if (!usedIds.contains(i)) {
          availableIds.add(i);
        }
      }

      // Zufällige neue Frage auswählen.
      final random = Random();

      final selectedIndex =
          availableIds[random.nextInt(availableIds.length)];

      // Frage sofort als benutzt speichern.
      usedIds.add(selectedIndex);

      await _prefs.setStringList(
        _usedQuestionsKey,
        usedIds.map((id) => id.toString()).toList(),
      );

      if (!mounted) return;

      setState(() {
        _language = savedLanguage == 'en' ? 'en' : 'de';
        _questionIndex = selectedIndex;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  // Antwort speichern und an nächsten Spieler übergeben.
  void _submitAnswer() {
    if (_finished || !_isReady) return;

    final answer = _answerController.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translate(
              'Bitte gib zuerst eine Antwort ein.',
              'Please enter an answer first.',
            ),
          ),
          backgroundColor: const Color(0xFF50316F),
        ),
      );
      return;
    }

    if (_currentPlayerIndex >= widget.players.length) {
      return;
    }

    final player = widget.players[_currentPlayerIndex];

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _answers[player] = answer;
      _answerController.clear();

      if (_currentPlayerIndex < widget.players.length - 1) {
        _currentPlayerIndex++;
        _isReady = false;
      } else {
        _finished = true;
        _isReady = false;
      }
    });
  }

  // Alle Antworten sind da: Judges auslosen.
  void _revealJudges() {
    if (_answers.length != widget.players.length) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RoleRevealScreen(
          players: widget.players,
          judgeCount: widget.judgeCount,
          question: _question,
          answers: Map<String, String>.from(_answers),
        ),
      ),
    );
  }

  // Wiederverwendbare violette Karte.
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

  // Einheitlicher Hauptbutton.
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

  // Fortschrittsanzeige.
  Widget _progressHeader() {
    final total = widget.players.length;
    final completed = _answers.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PROVE IT!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _lightPurple,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              _finished
                  ? _translate('ALLE FERTIG', 'ALL DONE')
                  : _translate(
                      'SPIELER ${_currentPlayerIndex + 1} / $total',
                      'PLAYER ${_currentPlayerIndex + 1} / $total',
                    ),
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            minHeight: 7,
            backgroundColor: const Color(0xFF38234F),
            valueColor: const AlwaysStoppedAnimation<Color>(
              _accent,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _translate(
              '$completed von $total Antworten gespeichert',
              '$completed of $total answers saved',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: _muted,
            ),
          ),
        ),
      ],
    );
  }

  // Das Handy wird an den nächsten Spieler übergeben.
  Widget _handoffScreen(String player) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: const BoxDecoration(
            color: Color(0xFF392250),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.phone_android_rounded,
            size: 65,
            color: _lightPurple,
          ),
        ),

        const SizedBox(height: 28),

        Text(
          _translate(
            '$player ist dran!',
            "It's $player's turn!",
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          _translate(
            'Gib das Handy an diese Person weiter.',
            'Pass the phone to this player.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: _muted,
          ),
        ),

        const SizedBox(height: 26),

        _card(
          child: Row(
            children: [
              const Icon(
                Icons.visibility_off_rounded,
                color: _accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _translate(
                    'Die Frage erscheint erst, '
                    'wenn du bereit bist.',
                    'The question will appear '
                    'when you are ready.',
                  ),
                  style: const TextStyle(
                    color: _lightPurple,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        _primaryButton(
          label: _translate(
            'ICH BIN BEREIT',
            "I'M READY",
          ),
          icon: Icons.visibility_rounded,
          onPressed: () {
            setState(() {
              _isReady = true;
            });
          },
        ),
      ],
    );
  }

  // Frage und geheime Antwort.
  Widget _answerScreen(String player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 15),

        Text(
          _translate(
            'HALLO, $player!',
            'HELLO, $player!',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _lightPurple,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          _translate(
            'Beantworte die Frage so, '
            'wie du wirklich antworten würdest.',
            'Answer the question '
            'the way you really would.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 30),

        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate('DEINE FRAGE', 'YOUR QUESTION'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: _accent,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        Text(
          _translate(
            'DEINE GEHEIME ANTWORT',
            'YOUR SECRET ANSWER',
          ),
          style: const TextStyle(
            color: _lightPurple,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _answerController,
          minLines: 3,
          maxLines: 5,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: _translate(
              'Schreibe deine Antwort ...',
              'Write your answer ...',
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF9985B0),
            ),
            filled: true,
            fillColor: const Color(0xFF1A102B),
            contentPadding: const EdgeInsets.all(18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: Color(0xFF695087),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: _accent,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        _card(
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: _accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _translate(
                    'Deine Antwort bleibt geheim, '
                    'bis alle fertig sind.',
                    'Your answer stays secret '
                    'until everyone is finished.',
                  ),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        _primaryButton(
          label: _translate(
            'ANTWORT BESTÄTIGEN',
            'SUBMIT ANSWER',
          ),
          icon: Icons.check_circle_outline_rounded,
          onPressed: _submitAnswer,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // Abschluss der Antwortphase.
  Widget _finishedScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: const BoxDecoration(
            color: Color(0xFF392250),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 70,
            color: _accent,
          ),
        ),

        const SizedBox(height: 28),

        Text(
          _translate(
            'ALLE ANTWORTEN ABGEGEBEN!',
            'ALL ANSWERS SUBMITTED!',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: _lightPurple,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          _translate(
            '${_answers.length} Antworten gespeichert',
            '${_answers.length} answers saved',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _accent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        _card(
          child: Column(
            children: [
              const Icon(
                Icons.gavel_rounded,
                size: 45,
                color: _accent,
              ),

              const SizedBox(height: 15),

              Text(
                _translate(
                  'Als Nächstes werden die Judges '
                  'zufällig ausgelost.',
                  'Next, the judges will be '
                  'selected at random.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _lightPurple,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        _primaryButton(
          label: _translate(
            'JUDGES AUSLOSEN',
            'REVEAL JUDGES',
          ),
          icon: Icons.casino_rounded,
          onPressed: _revealJudges,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
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

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text('PROVE IT!'),
          backgroundColor: _background,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: _accent,
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fragen konnten nicht geladen werden.\n'
                  'Could not load questions.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentPlayer = _finished
        ? ''
        : widget.players[_currentPlayerIndex];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _background,
        resizeToAvoidBottomInset: true,

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
        actions: const [
          RoundExitButton(),
        ],
      ),

        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  15,
                  22,
                  10,
                ),
                child: _progressHeader(),
              ),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    15,
                    22,
                    30,
                  ),
                  child: _finished
                      ? _finishedScreen()
                      : !_isReady
                          ? _handoffScreen(currentPlayer)
                          : _answerScreen(currentPlayer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
