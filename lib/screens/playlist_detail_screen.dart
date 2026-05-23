// Displays the contents of a specific user playlist.
// Allows for song removal and playlist deletion.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/playlist_model.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/screens/lyric_screen.dart';

/// Detailed view of a single playlist, showing all included tracks.
class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  /// Prompts the user to confirm the permanent deletion of the playlist.
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: const Text('Are you sure you want to delete this playlist? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _firestoreService.deletePlaylist(widget.playlist.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to playlist selection screen
              }
            },
            child: Text('Delete', style: TextStyle(color: context.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Playlist',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: FutureBuilder<List<Song>>(
        // Fetches song metadata for all IDs stored in the playlist.
        future: _firestoreService.getPlaylistSongs(widget.playlist.songIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('This playlist is empty. Add some songs to get started!'));
          }

          final songs = snapshot.data!;

          return ListView.builder(
            padding: context.paddingMD,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: context.radiusSM,
                  child: Image(
                    image: song.thumbnail()!.image,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(song.title(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(song.songAlbums.join(', ')),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remove from Playlist',
                  onPressed: () async {
                    // Removes the song ID from the Firestore array.
                    await _firestoreService.removeSongFromPlaylist(widget.playlist.id, song.id!);
                    setState(() {
                      widget.playlist.songIds.remove(song.id);
                    });
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LyricScreen(song: song)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
