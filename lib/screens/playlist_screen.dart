import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/playlist_model.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/screens/playlist_detail_screen.dart';
import 'package:kenoverse/screens/liked_songs_screen.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _showCreatePlaylistDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _CreatePlaylistScreen(
          currentUser: currentUser!,
          firestoreService: _firestoreService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlists')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please sign in to view your playlists'),
              context.gapMD,
              ElevatedButton(
                onPressed: () =>Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePlaylistDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: context.paddingMD,
            child: Card(
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: context.radiusSM,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.red),
                ),
                title: const Text('Liked Songs', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Your favorite tracks'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LikedSongsScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getUserPlaylists(currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No playlists yet.'),
                        context.gapMD,
                        ElevatedButton(
                          onPressed: _showCreatePlaylistDialog,
                          child: const Text('Create Your First Playlist'),
                        ),
                      ],
                    ),
                  );
                }

                var playlists = snapshot.data!.docs.map((doc) => Playlist.fromFirestore(doc)).toList();

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Padding(
                      padding: context.paddingHorizontal(AppConstants.spacingMD),
                      child: Card(
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: context.colorScheme.primaryContainer,
                              borderRadius: context.radiusSM,
                            ),
                            child: const Icon(Icons.playlist_play),
                          ),
                          title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${playlist.songIds.length} songs'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistDetailScreen(playlist: playlist),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar.bottomAppBar(context),
    );
  }
}

class _CreatePlaylistScreen extends StatefulWidget {
  final User currentUser;
  final FirestoreService firestoreService;

  const _CreatePlaylistScreen({required this.currentUser, required this.firestoreService});

  @override
  State<_CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<_CreatePlaylistScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Playlist'),
        actions: [
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Playlist newPlaylist = Playlist(
                  id: '',
                  userId: widget.currentUser.uid,
                  name: nameController.text,
                  description: descController.text,
                );
                await widget.firestoreService.createPlaylist(newPlaylist);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.paddingLG,
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            context.gapMD,
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
