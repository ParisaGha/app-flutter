
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'question_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  List<String> _players = [];
  Set<String> _selectedPlayers = {};

  int _judgeCount = 1;
  bool _isLoading = true;
  String _language = 'de';

  bool get isGerman => _language == 'de';

  static const Color _background = Color(0xFF130D21);
  static const Color _cardColor = Color(0xFF281A3E);
  static const Color _accent = Color(0xFFB585F9);
  static const Color _lightPurple = Color(0xFFE5D1FF);
  static const Color _muted = Color(0xFFBBA9D0);

  // Bisherige Judge-Empfehlung beibehalten
  int _recommendedJudges(int playerCount) {
    if (playerCount <= 5) return 1;
    if (playerCount <= 8) return 2;
    if (playerCount <= 11) return 3;
    if (playerCount <= 14) return 4;
    return 5;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Gespeicherte Spieler und Sprache laden
  Future<void> _loadData() async {
    final savedPlayers =
        await _prefs.getStringList('players') ?? [];

    final savedLanguage =
        await _prefs.getString('language');

    if (!mounted) return;

    setState(() {
      _players = savedPlayers;
      _selectedPlayers = savedPlayers.toSet();
      _language = savedLanguage == 'en' ? 'en' : 'de';

      // Judge-Anzahl passend zur Spielerzahl begrenzen
      final maximum = _calculateMaxJudges(savedPlayers.length);

      _judgeCount = _recommendedJudges(
        savedPlayers.length,
      ).clamp(1, maximum);

      _isLoading = false;
    });
  }

  int _calculateMaxJudges(int playerCount) {
    final available = playerCount - 2;

    if (available < 1) return 1;
    if (available > 5) return 5;

    return available;
  }

  // Mindestens zwei Nicht-Judges müssen übrig bleiben
  int get _maxJudges {
    return _calculateMaxJudges(_selectedPlayers.length);
  }

  // Spieler aktivieren oder deaktivieren
  void _togglePlayer(String name, bool selected) {
    setState(() {
      if (selected) {
        _selectedPlayers.add(name);
      } else {
        _selectedPlayers.remove(name);
      }

      if (_judgeCount > _maxJudges) {
        _judgeCount = _maxJudges;
      }
    });
  }

  // Alle Spieler auswählen
  void _selectAll() {
    setState(() {
      _selectedPlayers = _players.toSet();

      if (_judgeCount > _maxJudges) {
        _judgeCount = _maxJudges;
      }
    });
  }

  // Auswahl zurücksetzen
  void _clearSelection() {
    setState(() {
      _selectedPlayers.clear();
      _judgeCount = 1;
    });
  }

  // Zur Fragerunde wechseln
  void _startRound() {
    if (_selectedPlayers.length < 3) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(
          players: _players
              .where(
                (name) => _selectedPlayers.contains(name),
              )
              .toList(),
          judgeCount: _judgeCount,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF493267),
        ),
      ),
      child: child,
    );
  }

  Widget _playerTile(String name) {
    final selected = _selectedPlayers.contains(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? const Color(0xFF46305F)
            : const Color(0xFF1C142C),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _togglePlayer(name, !selected),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  activeColor: _accent,
                  checkColor: const Color(0xFF1D0D30),
                  side: const BorderSide(
                    color: _accent,
                    width: 1.5,
                  ),
                  onChanged: (value) {
                    _togglePlayer(name, value ?? false);
                  },
                ),

                const SizedBox(width: 8),

                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF603E83),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _lightPurple,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedPlayers.length;
    final canStart = selectedCount >= 3;

    final recommended = _recommendedJudges(
      selectedCount,
    ).clamp(1, _maxJudges);

    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isGerman
              ? 'SPIEL VORBEREITEN'
              : 'GAME SETUP',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _lightPurple,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _accent,
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Scrollbarer Inhalt
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 5),

                          const Icon(
                            Icons.groups_rounded,
                            size: 65,
                            color: _accent,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            isGerman
                                ? 'WER IST DABEI?'
                                : "WHO'S PLAYING?",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            isGerman
                                ? 'Wähle deine Mitspieler für '
                                  'die nächste Bluffrunde.'
                                : 'Choose your players '
                                  'for the next bluff round.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 26),

                          // Spielerauswahl
                          _sectionCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isGerman
                                            ? 'SPIELER AUSWÄHLEN'
                                            : 'SELECT PLAYERS',
                                        style: const TextStyle(
                                          color: _lightPurple,
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),

                                    Text(
                                      '$selectedCount / 20',
                                      style: const TextStyle(
                                        color: _accent,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Auswahlaktionen
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _players.isEmpty
                                          ? null
                                          : _selectAll,
                                      icon: const Icon(
                                        Icons.done_all_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isGerman
                                            ? 'Alle auswählen'
                                            : 'Select all',
                                      ),
                                    ),

                                    TextButton.icon(
                                      onPressed:
                                          _selectedPlayers.isEmpty
                                              ? null
                                              : _clearSelection,
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isGerman
                                            ? 'Auswahl löschen'
                                            : 'Clear selection',
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                if (_players.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 35,
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.person_add_alt_1_rounded,
                                          size: 52,
                                          color: Color(0xFF72558C),
                                        ),

                                        const SizedBox(height: 12),

                                        Text(
                                          isGerman
                                              ? 'Noch keine Spieler gespeichert.\n'
                                                'Füge zuerst Spieler hinzu.'
                                              : 'No players saved yet.\n'
                                                'Add players first.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: _muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ..._players.map(_playerTile),

                                const SizedBox(height: 5),

                                Text(
                                  isGerman
                                      ? '$selectedCount Spieler ausgewählt'
                                      : '$selectedCount players selected',
                                  style: const TextStyle(
                                    color: _accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Judge-Auswahl
                          _sectionCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.gavel_rounded,
                                      color: _accent,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'JUDGES',
                                        style: TextStyle(
                                          color: _lightPurple,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isGerman
                                          ? 'Anzahl der Judges'
                                          : 'Number of judges',
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),

                                    Text(
                                      '$_judgeCount',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight:
                                            FontWeight.w900,
                                        color: _accent,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: _accent,
                                    inactiveTrackColor:
                                        const Color(0xFF60477D),
                                    thumbColor: _lightPurple,
                                  ),
                                  child: Slider(
                                    min: 1,
                                    max: _maxJudges.toDouble(),
                                    divisions: _maxJudges > 1
                                        ? _maxJudges - 1
                                        : null,
                                    value: _judgeCount.toDouble(),
                                    onChanged: canStart
                                        ? (value) {
                                            setState(() {
                                              _judgeCount = value.round();
                                            });
                                          }
                                        : null,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  isGerman
                                      ? 'Empfehlung: $recommended '
                                        'Judge(s) bei $selectedCount Spielern'
                                      : 'Recommended: $recommended '
                                        'judge(s) for $selectedCount players',
                                  style: const TextStyle(
                                    color: _accent,
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  isGerman
                                      ? 'Mindestens zwei Spieler müssen '
                                        'Nicht-Judges bleiben.'
                                      : 'At least two players must '
                                        'remain non-judges.',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Startbutton bleibt unten sichtbar
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      20,
                    ),
                    decoration: const BoxDecoration(
                      color: _background,
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFF35234C),
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!canStart)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: Text(
                              isGerman
                                  ? 'Wähle mindestens 3 Spieler aus.'
                                  : 'Select at least 3 players.',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: FilledButton.icon(
                            onPressed: canStart ? _startRound : null,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 28,
                            ),
                            label: Text(
                              isGerman
                                  ? 'RUNDE STARTEN'
                                  : 'START ROUND',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor:
                                  const Color(0xFF1D0D30),
                              disabledBackgroundColor:
                                  const Color(0xFF49375A),
                              disabledForegroundColor:
                                  const Color(0xFF9A8CA8),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(35),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
