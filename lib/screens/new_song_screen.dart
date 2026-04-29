import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewSong extends StatefulWidget {
  const NewSong({super.key});
  @override
  State<NewSong> createState() => _NewSongState();
}

class _NewSongState extends State<NewSong> {
  final FirestoreService _firestoreService = FirestoreService();
  static const List<String> _knownArtists = <String>[
    'シロネコ', 'Keno', 'Hatsune Miku', 'Megurine Luka', 'Kagamine Rin', 'Kagamine Len',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _spotifyController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _albumController = TextEditingController();

  DateTime? _selectedDate;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _processSong({required bool asDraft}) {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    Song newSong = Song(
      _titleController.text,
      isDraft: asDraft,
      songLanguage: _languageController.text.isEmpty ? null : _languageController.text,
      songAlbum: _albumController.text.isEmpty ? null : _albumController.text,
      songReleaseDate: _selectedDate,
      songFeaturedArtist: _artistController.text.isEmpty ? null : _artistController.text,
      songYoutubeUrl: _youtubeController.text.isEmpty ? null : _youtubeController.text,
      songSpotifyUrl: _spotifyController.text.isEmpty ? null : _spotifyController.text,
    );
    
    newSong.addLyrics(_lyricsController.text);
    if (_selectedImage != null) {
      newSong.addThumbnail(Image.file(_selectedImage!));
    }

    if (!asDraft) {
      _firestoreService.addSong({
        'title': _titleController.text,
        'lyrics': _lyricsController.text,
        'album': _albumController.text,
        'artist': _artistController.text,
        'language': _languageController.text,
        'releaseDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'youtubeUrl': _youtubeController.text,
        'spotifyUrl': _spotifyController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(asDraft ? 'Draft saved locally' : 'Song uploaded successfully!'),
        backgroundColor: asDraft ? null : Theme.of(context).colorScheme.primary,
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
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Release'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker Section
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('Add Artwork', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ],
                        )
                      : null,
                ),
              ),
            ),

            _buildSectionHeader('Basic Info', Icons.info_outline),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('Song Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lyricsController,
              maxLines: 8,
              decoration: _inputDecoration('Lyrics'),
            ),

            _buildSectionHeader('Metadata', Icons.settings_outlined),
            TextField(
              controller: _albumController,
              decoration: _inputDecoration('Album Name', prefixIcon: Icons.album),
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') return const Iterable<String>.empty();
                return _knownArtists.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (selection) => _artistController.text = selection,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (controller.text != _artistController.text && _artistController.text.isNotEmpty) {
                  controller.text = _artistController.text;
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (val) => _artistController.text = val,
                  decoration: _inputDecoration('Featured Artist', prefixIcon: Icons.person_outline),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _languageController,
                    decoration: _inputDecoration('Language'),
                  ),
                ),
                const SizedBox(width: 16),
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
            const SizedBox(height: 16),
            TextField(
              controller: _spotifyController,
              decoration: _inputDecoration('Spotify URL', prefixIcon: Icons.library_music),
            ),

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _processSong(asDraft: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _processSong(asDraft: false),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Post Song'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
