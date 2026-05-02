import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:intl/intl.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';

class NewSong extends StatefulWidget {
  final Song? existingSong;
  const NewSong({super.key, this.existingSong});
  @override
  State<NewSong> createState() => _NewSongState();
}

class _NewSongState extends State<NewSong> {
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _titleController;
  late TextEditingController _lyricsController;
  late TextEditingController _youtubeController;
  late TextEditingController _spotifyController;
  late TextEditingController _languageController;
  late TextEditingController _albumController;
  late TextEditingController _thumbnailController;

  // Multi-artist controllers
  late TextEditingController _originalArtistController;
  late TextEditingController _vocalsController;
  late TextEditingController _featuredArtistController;
  late TextEditingController _audioController;
  late TextEditingController _arrangementController;
  late TextEditingController _artworkController;
  late TextEditingController _videoController;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final song = widget.existingSong;
    _titleController = TextEditingController(text: song?.songTitle);
    _lyricsController = TextEditingController(text: song?.songLyrics);
    _youtubeController = TextEditingController(text: song?.songYoutubeUrl);
    _spotifyController = TextEditingController(text: song?.songSpotifyUrl);
    _languageController = TextEditingController(text: song?.songLanguage);
    _albumController = TextEditingController(text: song?.songAlbums.join(', '));
    _thumbnailController = TextEditingController(text: song?.songThumbnailUrl);

    _originalArtistController = TextEditingController(text: song?.originalArtists.join(', '));
    _vocalsController = TextEditingController(text: song?.vocals.join(', '));
    _featuredArtistController = TextEditingController(text: song?.featuredArtists.join(', '));
    _audioController = TextEditingController(text: song?.audioPreedit.join(', '));
    _arrangementController = TextEditingController(text: song?.arrangement.join(', '));
    _artworkController = TextEditingController(text: song?.artworkBy.join(', '));
    _videoController = TextEditingController(text: song?.videoBy.join(', '));
    _selectedDate = song?.songReleaseDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    _youtubeController.dispose();
    _spotifyController.dispose();
    _languageController.dispose();
    _albumController.dispose();
    _thumbnailController.dispose();
    _originalArtistController.dispose();
    _vocalsController.dispose();
    _featuredArtistController.dispose();
    _audioController.dispose();
    _arrangementController.dispose();
    _artworkController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  List<String> _parseArtists(String text) {
    if (text.isEmpty) return [];
    return text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  void _processSong({required bool asDraft}) {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final originalArtists = _parseArtists(_originalArtistController.text);
    final vocals = _parseArtists(_vocalsController.text);
    final featuredArtists = _parseArtists(_featuredArtistController.text);
    final audioPreedit = _parseArtists(_audioController.text);
    final arrangement = _parseArtists(_arrangementController.text);
    final artworkBy = _parseArtists(_artworkController.text);
    final videoBy = _parseArtists(_videoController.text);

    // Create a flattened search array for artist profiles
    final allContributors = {
      ...originalArtists,
      ...vocals,
      ...featuredArtists,
      ...audioPreedit,
      ...arrangement,
      ...artworkBy,
      ...videoBy,
    }.map((s) => s.toLowerCase().trim()).toList();

    final songData = {
      'title': _titleController.text,
      'lyrics': _lyricsController.text,
      'albums': _parseArtists(_albumController.text),
      'language': _languageController.text,
      'releaseDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
      'youtubeUrl': _youtubeController.text,
      'spotifyUrl': _spotifyController.text,
      'thumbnailUrl': _thumbnailController.text.isEmpty ? null : _thumbnailController.text,
      'originalArtists': originalArtists,
      'vocals': vocals,
      'featuredArtists': featuredArtists,
      'audioPreedit': audioPreedit,
      'arrangement': arrangement,
      'artworkBy': artworkBy,
      'videoBy': videoBy,
      'allContributors': allContributors,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (!asDraft) {
      if (widget.existingSong?.id != null) {
        _firestoreService.updateSong(widget.existingSong!.id!, songData);
      } else {
        _firestoreService.addSong(songData);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(asDraft 
          ? 'Draft saved locally' 
          : (widget.existingSong != null ? 'Song updated successfully!' : 'Song uploaded successfully!')),
        backgroundColor: asDraft ? null : context.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colorScheme.primary),
          context.gapSM,
          Text(
            title.toUpperCase(),
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? prefixIcon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      filled: true,
      fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: context.radiusMD,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: context.radiusMD,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: context.radiusMD,
        borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSong != null ? 'Edit Release' : 'New Release'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image URL Section
            Center(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: context.radiusXL,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _thumbnailController.text.isNotEmpty
                        ? ClipRRect(
                            borderRadius: context.radiusXL,
                            child: Image.network(
                              _thumbnailController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                                color: context.colorScheme.error,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 40, color: context.colorScheme.primary),
                              context.gapSM,
                              Text('Image Preview', style: TextStyle(color: context.colorScheme.primary)),
                            ],
                          ),
                  ),
                  context.gapMD,
                  TextField(
                    controller: _thumbnailController,
                    onChanged: (value) => setState(() {}),
                    decoration: _inputDecoration('Artwork URL', prefixIcon: Icons.link),
                  ),
                ],
              ),
            ),

            _buildSectionHeader('Basic Info', Icons.info_outline),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('Song Title'),
            ),
            context.gapMD,
            TextField(
              controller: _lyricsController,
              maxLines: 8,
              decoration: _inputDecoration('Lyrics'),
            ),

            _buildSectionHeader('Artists & Credits', Icons.people_outline),
            TextField(
              controller: _originalArtistController,
              decoration: _inputDecoration('Original Artist(s)', hint: 'Separate with commas'),
            ),
            context.gapMD,
            TextField(
              controller: _vocalsController,
              decoration: _inputDecoration('Vocal(s)', hint: 'Separate with commas'),
            ),
            context.gapMD,
            TextField(
              controller: _featuredArtistController,
              decoration: _inputDecoration('Featured Artist(s)', hint: 'Separate with commas'),
            ),
            context.gapMD,
            TextField(
              controller: _audioController,
              decoration: _inputDecoration('Audio/Mixing', hint: 'Separate with commas'),
            ),
            context.gapMD,
            TextField(
              controller: _arrangementController,
              decoration: _inputDecoration('Arrangement', hint: 'Separate with commas'),
            ),
            context.gapMD,
            TextField(
              controller: _artworkController,
              decoration: _inputDecoration('Artwork By', hint: 'Separate with commas'),
            ),
            context.gapMD,
            TextField(
              controller: _videoController,
              decoration: _inputDecoration('Video By', hint: 'Separate with commas'),
            ),

            _buildSectionHeader('Metadata', Icons.settings_outlined),
            TextField(
              controller: _albumController,
              decoration: _inputDecoration('Album(s)', prefixIcon: Icons.album, hint: 'Separate with commas'),
            ),
            context.gapMD,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _languageController,
                    decoration: _inputDecoration('Language'),
                  ),
                ),
                context.gapMD,
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: _inputDecoration('Release Date'),
                      child: Text(
                        _selectedDate == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(_selectedDate!),
                        style: TextStyle(fontSize: 14, color: _selectedDate == null ? Theme.of(context).hintColor : null),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            _buildSectionHeader('Streaming Links', Icons.link),
            TextField(
              controller: _youtubeController,
              decoration: _inputDecoration('YouTube URL', prefixIcon: Icons.play_circle_fill),
            ),
            context.gapMD,
            TextField(
              controller: _spotifyController,
              decoration: _inputDecoration('Spotify URL', prefixIcon: Icons.library_music),
            ),

            context.gapXXL,
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            if (widget.existingSong == null)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _processSong(asDraft: true),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: context.radiusMD),
                  ),
                  child: const Text('Save Draft'),
                ),
              ),
            if (widget.existingSong == null) context.gapMD,
            Expanded(
              child: FilledButton(
                onPressed: () => _processSong(asDraft: false),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: context.radiusMD),
                ),
                child: Text(widget.existingSong != null ? 'Update Song' : 'Post Song'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
