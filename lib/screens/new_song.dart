import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class NewSong extends StatefulWidget {
  const NewSong({super.key});
  @override
  State<NewSong> createState() => _NewSongState();
}

class _NewSongState extends State<NewSong> {
  // Known artists for suggestions
  static const List<String> _knownArtists = <String>[
    'シロネコ',
    'Keno',
    'Hatsune Miku',
    'Megurine Luka',
    'Kagamine Rin',
    'Kagamine Len',
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
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  String _formatDate(DateTime date) {
    var day = date.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1: suffix = 'st'; break;
        case 2: suffix = 'nd'; break;
        case 3: suffix = 'rd'; break;
        default: suffix = 'th';
      }
    }
    return "$day$suffix ${DateFormat('MMMM yyyy').format(date)}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _processSong({required bool asDraft}) {
    String title = _titleController.text;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    Song newSong = Song(
      title,
      isDraft: asDraft,
      language: _languageController.text.isEmpty ? null : _languageController.text,
      album: _albumController.text.isEmpty ? null : _albumController.text,
      releaseDate: _selectedDate,
      featuredArtist: _artistController.text.isEmpty ? null : _artistController.text,
      youtubeUrl: _youtubeController.text.isEmpty ? null : _youtubeController.text,
      spotifyUrl: _spotifyController.text.isEmpty ? null : _spotifyController.text,
    );
    
    newSong.addLyrics(_lyricsController.text);
    if (_selectedImage != null) {
      newSong.addThumbnail(Image.file(_selectedImage!));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(asDraft ? 'Draft saved locally' : 'Song uploaded successfully!'),
        backgroundColor: asDraft ? null : Colors.blue,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Song')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.fitHeight)
                      : null,
                ),
                child: _selectedImage == null
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Song Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _lyricsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Lyrics',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _languageController,
              decoration: const InputDecoration(
                labelText: 'Language (e.g., Japanese, English)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ListTile(
              title: Text(_selectedDate == null ? 'Select Release Date' : _formatDate(_selectedDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(
                labelText: 'Album (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            
            // Autocomplete for Featured Artist
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return _knownArtists.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _artistController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Initialize autocomplete controller with current state
                if (controller.text != _artistController.text && _artistController.text.isNotEmpty) {
                   controller.text = _artistController.text;
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (val) => _artistController.text = val,
                  decoration: const InputDecoration(
                    labelText: 'Featured Artist (Optional)',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _youtubeController,
              decoration: const InputDecoration(
                labelText: 'YouTube URL (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.play_circle_fill),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _spotifyController,
              decoration: const InputDecoration(
                labelText: 'Spotify URL (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.library_music),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _processSong(asDraft: true),
                    child: const Text('Save as Draft'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _processSong(asDraft: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post Song'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// todo: make each section collapsible
// todo: make a autocomplete data file
// todo: add a "credit"/"behind the scenes" section