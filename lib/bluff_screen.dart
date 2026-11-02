
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'question_screen.dart';
import 'round_exit_button.dart';

class BluffScreen extends StatefulWidget {
  final String question;
  final String answer;
  final String realOne;
  final List<String> judges;
  final List<String> candidates;
  final List<String> players;
  final int judgeCount;

  const BluffScreen({
    super.key,
    required this.question,
    required this.answer,
    required this.realOne,
    required this.judges,
    required this.candidates,
    required this.players,
    required this.judgeCount,
  });

  @override
  State<BluffScreen> createState() => _BluffScreenState();
}

class _BluffScreenState extends State<BluffScreen> {
  static const Color _background = Color(0xFF130D21);
  static const Color _cardColor = Color(0xFF281A3E);
  static const Color _accent = Color(0xFFB585F9);
  static const Color _lightPurple = Color(0xFFE5D1FF);
  static const Color _muted = Color(0xFFBBA9D0);

  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  late final List<String> _remainingPlayers;
  final List<String> _eliminatedPlayers = [];

  bool _finished = false;
  bool _isLoading = true;
  String _language = 'de';

  bool get isGerman => _language == 'de';

  String _translate(String de, String en) {
    return isGerman ? de : en;
  }

  @override
  void initState() {
    super.initState();
    _remainingPlayers =
        List<String>.from(widget.candidates);
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

  // Eliminierung mit Sicherheitsabfrage.
  Future<void> _confirmElimination(String player) async {
    if (_finished || !_remainingPlayers.contains(player)) {
      return;
    }

    final singleJudge = widget.judges.length == 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
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
                color: _accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _translate(
                    'Person eliminieren?',
                    'Eliminate player?',
                  ),
                  style: const TextStyle(
                    color: _lightPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _translate(
              singleJudge
                  ? 'Du möchtest $player eliminieren.\n\n'
                    'Bist du sicher?\n\n'
                    'Diese Entscheidung kann nicht '
                    'rückgängig gemacht werden.'
                  : 'Ihr möchtet $player eliminieren.\n\n'
                    'Sind alle Judges einverstanden?\n\n'
                    'Diese Entscheidung kann nicht '
                    'rückgängig gemacht werden.',
              singleJudge
                  ? 'You want to eliminate $player.\n\n'
                    'Are you sure?\n\n'
                    'This decision cannot be undone.'
                  : 'You want to eliminate $player.\n\n'
                    'Do all judges agree?\n\n'
                    'This decision cannot be undone.',
            ),
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
                _translate('ABBRECHEN', 'CANCEL'),
                style: const TextStyle(
                  color: _lightPurple,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: const Color(0xFF1D0D30),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                _translate('ELIMINIEREN', 'ELIMINATE'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;
    if (!_remainingPlayers.contains(player)) return;

    setState(() {
      _remainingPlayers.remove(player);
      _eliminatedPlayers.add(player);

      // Identität bis zum Finale geheim halten.
      if (_remainingPlayers.length == 1) {
        _finished = true;
      }
    });
  }

  // Nächste unabhängige Runde.
  void _nextRound() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
          players: List<String>.from(widget.players),
          judgeCount: widget.judgeCount,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPurple,
          side: const BorderSide(
            color: _accent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
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

      // NEU: Abbrechen-Button rechts oben.
      actions: const [
        RoundExitButton(),
      ],
    );
  }

  // Frage und ausgewählte Antwort.
  Widget _questionAndAnswer() {
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate('DIE FRAGE', 'THE QUESTION'),
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
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
                color: _accent,
                size: 35,
              ),
              const SizedBox(height: 12),
              Text(
                widget.answer,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _candidateTile(String player) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _confirmElimination(player),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF493267),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF603E83),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _lightPurple,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    player,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.cancel_outlined,
                  color: Color(0xFFEF9BB6),
                  size: 29,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HAUPTSPIEL: BLUFFRUNDE
  Widget _buildBluffScreen() {
    final singleJudge = widget.judges.length == 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _background,
        appBar: _appBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20, 15, 20, 35,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Icon(
                    Icons.theater_comedy_rounded,
                    size: 58,
                    color: _accent,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _translate(
                    'DIE BLUFFRUNDE',
                    'THE BLUFF ROUND',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: _lightPurple,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  _translate(
                    'WER BLUFFT? WER SAGT DIE WAHRHEIT?',
                    "WHO'S BLUFFING? WHO'S TELLING THE TRUTH?",
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                _questionAndAnswer(),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _translate(
                          'DIE VERDÄCHTIGEN',
                          'THE SUSPECTS',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _lightPurple,
                        ),
                      ),
                    ),
                    Text(
                      _translate(
                        '${_remainingPlayers.length} ÜBRIG',
                        '${_remainingPlayers.length} LEFT',
                      ),
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                _card(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.gavel_rounded,
                        size: 30,
                        color: _accent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _translate(
                          singleJudge
                              ? 'Wem glaubst du nicht?'
                              : 'Wem glaubt ihr nicht?',
                          'Who do you not believe?',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _lightPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!singleJudge) ...[
                        const SizedBox(height: 10),
                        Text(
                          _translate(
                            'Alle Judges müssen sich '
                            'auf eine Person einigen.',
                            'All judges must agree '
                            'on one player.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                for (final player in _remainingPlayers)
                  _candidateTile(player),

                const SizedBox(height: 12),

                Text(
                  _translate(
                    'Tippe auf eine Person, '
                    'um ihre Eliminierung zu bestätigen.',
                    'Tap a player to confirm their elimination.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _muted,
                  ),
                ),

                if (_eliminatedPlayers.isNotEmpty) ...[
                  const SizedBox(height: 30),

                  Text(
                    _translate(
                      'BEREITS ELIMINIERT',
                      'ALREADY ELIMINATED',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _lightPurple,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _card(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        for (int i = 0;
                            i < _eliminatedPlayers.length;
                            i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFEF9BB6),
                                  size: 19,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${i + 1}. '
                                    '${_eliminatedPlayers[i]}',
                                    style: const TextStyle(
                                      color: _muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FINALE UND GEWINNER
  Widget _buildFinalScreen() {
    final lastPlayer = _remainingPlayers.first;
    final judgesWon = lastPlayer == widget.realOne;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _background,
        appBar: _appBar(),

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                22, 20, 22, 35,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 550,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF392250),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6A468D),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        judgesWon
                            ? Icons.emoji_events_rounded
                            : Icons.theater_comedy_rounded,
                        size: 62,
                        color: _lightPurple,
                      ),
                    ),

                    const SizedBox(height: 27),

                    Text(
                      judgesWon
                          ? 'THE JUDGES &\nTHE REAL ONE WIN!'
                          : 'THE BLUFFER WINS!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _lightPurple,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      judgesWon
                          ? _translate(
                              'Ihr habt die Wahrheit gefunden!',
                              'You found the truth!',
                            )
                          : _translate(
                              'Die Judges wurden getäuscht!',
                              'The judges were fooled!',
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _muted,
                      ),
                    ),

                    const SizedBox(height: 25),

                    _card(
                      child: Column(
                        children: [
                          Text(
                            judgesWon
                                ? _translate(
                                    'LETZTE VERDÄCHTIGE PERSON',
                                    'LAST SUSPECT',
                                  )
                                : _translate(
                                    'GEWINNER',
                                    'WINNER',
                                  ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 13),
                          Text(
                            lastPlayer.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // THE REAL ONE erst jetzt enthüllen.
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
                            Icons.visibility_rounded,
                            size: 38,
                            color: _accent,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'THE REAL ONE WAS...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _lightPurple,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.realOne.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    _card(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.format_list_numbered_rounded,
                                color: _accent,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _translate(
                                    'ELIMINIERUNGSREIHENFOLGE',
                                    'ELIMINATION ORDER',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _lightPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          for (int i = 0;
                              i < _eliminatedPlayers.length;
                              i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 7,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 27,
                                    height: 27,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF603E83),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: _lightPurple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _eliminatedPlayers[i],
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFFEF9BB6),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    _primaryButton(
                      label: _translate(
                        'NÄCHSTE RUNDE',
                        'NEXT ROUND',
                      ),
                      icon: Icons.refresh_rounded,
                      onPressed: _nextRound,
                    ),

                    const SizedBox(height: 14),

                    _secondaryButton(
                      label: _translate(
                        'HAUPTMENÜ',
                        'MAIN MENU',
                      ),
                      icon: Icons.home_rounded,
                      onPressed: _goHome,
                    ),
                  ],
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

    if (_finished) {
      return _buildFinalScreen();
    }

    return _buildBluffScreen();
  }
}
