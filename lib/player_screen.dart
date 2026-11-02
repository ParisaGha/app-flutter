
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  List<String> _players = [];

  bool _isLoading = true;
  bool _isSaving = false;

  String _language = 'de';

  bool get isGerman => _language == 'de';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Spieler und gespeicherte Sprache laden
  Future<void> _loadData() async {
    final savedPlayers =
        await _prefs.getStringList('players');

    final savedLanguage =
        await _prefs.getString('language');

    if (!mounted) return;

    setState(() {
      _players = savedPlayers ?? [];
      _language = savedLanguage == 'en' ? 'en' : 'de';
      _isLoading = false;
    });
  }

  // Spieler dauerhaft speichern
  Future<void> _savePlayers() async {
    await _prefs.setStringList('players', _players);
  }

  // Neuen Spieler hinzufügen
  Future<void> _addPlayer() async {
    final name = _nameController.text.trim();

    if (_isLoading || _isSaving || name.isEmpty) {
      return;
    }

    if (_players.length >= 20) {
      _showMessage(
        isGerman
            ? 'Maximal 20 Spieler erlaubt.'
            : 'A maximum of 20 players is allowed.',
      );
      return;
    }

    if (_players.any(
      (player) =>
          player.toLowerCase() == name.toLowerCase(),
    )) {
      _showMessage(
        isGerman
            ? 'Dieser Name ist bereits vorhanden.'
            : 'This name already exists.',
      );
      return;
    }

    setState(() {
      _players.add(name);
      _nameController.clear();
      _isSaving = true;
    });

    try {
      await _savePlayers();
    } catch (_) {
      if (mounted) {
        setState(() {
          _players.remove(name);
        });

        _showMessage(
          isGerman
              ? 'Spieler konnte nicht gespeichert werden.'
              : 'Could not save player.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Spieler entfernen
  Future<void> _removePlayer(int index) async {
    if (_isSaving || index >= _players.length) {
      return;
    }

    final removedName = _players[index];

    setState(() {
      _players.removeAt(index);
      _isSaving = true;
    });

    try {
      await _savePlayers();
    } catch (_) {
      if (mounted) {
        setState(() {
          _players.insert(index, removedName);
        });

        _showMessage(
          isGerman
              ? 'Spieler konnte nicht gelöscht werden.'
              : 'Could not delete player.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Meldung anzeigen
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF50316F),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF130D21);
    const cardColor = Color(0xFF281A3E);
    const accent = Color(0xFFB585F9);
    const lightPurple = Color(0xFFE5D1FF);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          isGerman
              ? 'SPIELER VERWALTEN'
              : 'MANAGE PLAYERS',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: lightPurple,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: accent,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // Überschrift
                    const Center(
                      child: Icon(
                        Icons.groups_rounded,
                        size: 65,
                        color: accent,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      isGerman
                          ? 'DEINE CREW. DEIN SPIEL.'
                          : 'YOUR CREW. YOUR GAME.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: lightPurple,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isGerman
                          ? 'Verwalte deine Mitspieler '
                            'für die nächste Bluffrunde.'
                          : 'Manage your players '
                            'for the next bluff round.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFBBA9D0),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Bereich: Spieler hinzufügen
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF493267),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isGerman
                                      ? 'NEUEN SPIELER HINZUFÜGEN'
                                      : 'ADD NEW PLAYER',
                                  style: const TextStyle(
                                    color: lightPurple,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              Text(
                                '${_players.length} / 20',
                                style: const TextStyle(
                                  color: accent,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller:
                                      _nameController,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  textInputAction:
                                      TextInputAction.done,
                                  onSubmitted: (_) =>
                                      _addPlayer(),
                                  decoration: InputDecoration(
                                    hintText: isGerman
                                        ? 'Spielername ...'
                                        : 'Player name ...',
                                    hintStyle:
                                        const TextStyle(
                                      color:
                                          Color(0xFF9985B0),
                                    ),
                                    filled: true,
                                    fillColor:
                                        const Color(0xFF140D23),
                                    border:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        13,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color:
                                            Color(0xFF6D498F),
                                      ),
                                    ),
                                    enabledBorder:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        13,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color:
                                            Color(0xFF6D498F),
                                      ),
                                    ),
                                    focusedBorder:
                                        OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        13,
                                      ),
                                      borderSide:
                                          const BorderSide(
                                        color: accent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              SizedBox(
                                width: 54,
                                height: 54,
                                child: FilledButton(
                                  onPressed: _isSaving
                                      ? null
                                      : _addPlayer,
                                  style:
                                      FilledButton.styleFrom(
                                    backgroundColor:
                                        accent,
                                    foregroundColor:
                                        const Color(0xFF1D0D30),
                                    padding:
                                        EdgeInsets.zero,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        13,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Überschrift der Liste
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isGerman
                                ? 'GESPEICHERTE SPIELER'
                                : 'SAVED PLAYERS',
                            style: const TextStyle(
                              color: lightPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                          ),
                        ),

                        Text(
                          '${_players.length}',
                          style: const TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Spielerliste
                    Expanded(
                      child: _players.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 55,
                                    color:
                                        Color(0xFF72558C),
                                  ),

                                  const SizedBox(
                                    height: 15,
                                  ),

                                  Text(
                                    isGerman
                                        ? 'Noch keine Spieler gespeichert.'
                                        : 'No players saved yet.',
                                    textAlign:
                                        TextAlign.center,
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(0xFFBBA9D0),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior
                                      .onDrag,
                              itemCount:
                                  _players.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(
                                height: 10,
                              ),
                              itemBuilder:
                                  (context, index) {
                                final name =
                                    _players[index];

                                return Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: cardColor,
                                    borderRadius:
                                        BorderRadius.circular(
                                      16,
                                    ),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF493267,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 45,
                                        height: 45,
                                        decoration:
                                            const BoxDecoration(
                                          color: Color(
                                            0xFF603E83,
                                          ),
                                          shape:
                                              BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: lightPurple,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 14,
                                      ),

                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style:
                                              const TextStyle(
                                            fontSize: 17,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        tooltip: isGerman
                                            ? 'Spieler löschen'
                                            : 'Delete player',
                                        onPressed: _isSaving
                                            ? null
                                            : () =>
                                                _removePlayer(
                                                  index,
                                                ),
                                        icon: const Icon(
                                          Icons
                                              .delete_outline_rounded,
                                          color: Color(
                                            0xFFD0A5F2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      isGerman
                          ? 'Deine Spieler bleiben gespeichert, '
                            'auch wenn du die App schließt.'
                          : 'Your players stay saved, '
                            'even after closing the app.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9985B0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
