// Provides a standard bottom sheet menu for song-related interactions.
// Allows users to like, add to playlist, edit, or delete a song.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/screens/new_song_screen.dart';
import 'package:kenoverse/screens/add_version_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kenoverse/functionality/playlist_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/functionality/download_service.dart';

class SongActions {
  static void showSongMenu(BuildContext context, Song song) {
    final downloadService = DownloadService();
    final bool isDownloaded = downloadService.isDownloaded(song);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: context.radiusXL.topRight),
      ),
      builder: (context) {
        final user = FirebaseAuth.instance.currentUser;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: context.paddingMD,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: context.radiusSM,
                      child: Image(
                        image: song.thumbnail()!.image,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    context.gapMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title(),
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.songAlbums.isNotEmpty ? song.songAlbums.join(', ') : 'Single',
                            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.secondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (user != null)
                StreamBuilder<bool>(
                  stream: FirestoreService().isLiked(user.uid, song.id!),
                  builder: (context, snapshot) {
                    bool isLiked = snapshot.data ?? false;
                    return ListTile(
                      leading: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      title: Text(isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs'),
                      onTap: () {
                        FirestoreService().toggleLike(user.uid, song.id!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ListTile(
                leading: Icon(
                  isDownloaded ? Icons.file_download_done : Icons.file_download,
                  color: isDownloaded ? context.colorScheme.primary : null,
                ),
                title: Text(isDownloaded ? 'Downloaded' : 'Download for Offline'),
                onTap: isDownloaded ? null : () async {
                  Navigator.pop(context);
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading ${song.songTitle}...')),
                    );
                    await downloadService.downloadSongAudio(song);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download complete!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download failed: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(context, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add Version'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddVersionScreen(song: song)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Song'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewSong(existingSong: song)),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: context.colorScheme.error),
                title: Text('Delete Song', style: TextStyle(color: context.colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, song);
                },
              ),
              context.gapSM,
            ],
          ),
        );
      },
    );
  }

  static void _showAddToPlaylistDialog(BuildContext context, Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to add to playlist')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getUserPlaylists(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Text('No playlists found. Create one to get started.');

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final playlist = Playlist.fromFirestore(snapshot.data!.docs[index]);
                  final isAlreadyAdded = playlist.songIds.contains(song.id);
                  
                  return ListTile(
                    title: Text(playlist.name),
                    trailing: isAlreadyAdded ? Icon(Icons.check_circle, color: context.colorScheme.primary) : null,
                    subtitle: isAlreadyAdded ? const Text('Already added') : null,
                    onTap: isAlreadyAdded ? null : () async {
                      await FirestoreService().addSongToPlaylist(playlist.id, song.id!);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to ${playlist.name}')));
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  static void _showDeleteConfirmationDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "${song.title()}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (song.id != null) {
                await FirestoreService().deleteSong(song.id!);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Song deleted successfully')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: context.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
