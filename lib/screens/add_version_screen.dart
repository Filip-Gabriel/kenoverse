// Allows users to contribute alternative audio versions or translations for a song.
// Provides a segmented interface for switching between audio and lyric contributions.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';

enum AddMode { audio, lyrics }

class AddVersionScreen extends StatefulWidget {
  final Song song;
  const AddVersionScreen({super.key, required this.song});

  @override
  State<AddVersionScreen> createState() => _AddVersionScreenState();
}

class _AddVersionScreenState extends State<AddVersionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  static const List<String> _suggestedLanguages = ['English', 'Japanese', 'Romanized'];
  static const List<String> _suggestedAudioNames = ['Stripped', 'Sped Up', 'Remix'];

  final _audioNameController = TextEditingController();
  final _audioYoutubeController = TextEditingController();
  final _audioSpotifyController = TextEditingController();

  final _lyricLanguageController = TextEditingController();
  final _lyricsController = TextEditingController();

  AddMode _currentMode = AddMode.audio;

  @override
  void dispose() {
    _audioNameController.dispose();
    _audioNameController.dispose();
    _audioYoutubeController.dispose();
    _audioSpotifyController.dispose();
    _lyricLanguageController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_currentMode == AddMode.audio) {
      if (_audioNameController.text.isEmpty) return;
      
      final newVersion = AudioVersion(
        name: _audioNameController.text,
        youtubeUrl: _audioYoutubeController.text.isEmpty ? null : _audioYoutubeController.text,
        spotifyUrl: _audioSpotifyController.text.isEmpty ? null : _audioSpotifyController.text,
      );

      final updatedVersions = [...?widget.song.audioVersions, newVersion];
      await _firestoreService.updateSong(widget.song.id!, {
        'audioVersions': updatedVersions.map((v) => v.toMap()).toList(),
      });
    } else if (_currentMode == AddMode.lyrics) {
      if (_lyricLanguageController.text.isEmpty || _lyricsController.text.isEmpty) return;

      final newVersion = LyricVersion(
        language: _lyricLanguageController.text,
        lyrics: _lyricsController.text,
      );

      final updatedVersions = [...?widget.song.lyricVersions, newVersion];
      await _firestoreService.updateSong(widget.song.id!, {
        'lyricVersions': updatedVersions.map((v) => v.toMap()).toList(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Version added successfully!')),
      );
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(borderRadius: context.radiusMD, borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Version to ${widget.song.songTitle}'),
      ),
      body: SingleChildScrollView(
        padding: context.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SegmentedButton<AddMode>(
                segments: const [
                  ButtonSegment(value: AddMode.audio, label: Text('Audio'), icon: Icon(Icons.audiotrack)),
                  ButtonSegment(value: AddMode.lyrics, label: Text('Lyrics'), icon: Icon(Icons.lyrics)),
                ],
                selected: {_currentMode},
                onSelectionChanged: (val) => setState(() => _currentMode = val.first),
              ),
            ),
            context.gapLG,
            if (_currentMode == AddMode.audio) ...[
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  return _suggestedAudioNames.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _audioNameController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text != _audioNameController.text && _audioNameController.text.isNotEmpty) {
                    controller.text = _audioNameController.text;
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => _audioNameController.text = val,
                    decoration: _inputDecoration('Version Name (e.g. Sped Up)'),
                  );
                },
              ),
              context.gapMD,
              TextField(controller: _audioYoutubeController, decoration: _inputDecoration('YouTube URL')),
              context.gapMD,
              TextField(controller: _audioSpotifyController, decoration: _inputDecoration('Spotify URL')),
            ] else ...[
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  return _suggestedLanguages.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _lyricLanguageController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text != _lyricLanguageController.text && _lyricLanguageController.text.isNotEmpty) {
                    controller.text = _lyricLanguageController.text;
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => _lyricLanguageController.text = val,
                    decoration: _inputDecoration('Language (e.g. Romanized)'),
                  );
                },
              ),
              context.gapMD,
              TextField(
                controller: _lyricsController, 
                maxLines: 8, 
                decoration: _inputDecoration('Lyrics'),
              ),
            ],
            context.gapXL,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Add Version'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
