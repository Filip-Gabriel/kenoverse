import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/screens/lyric_screen.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Liked Songs')),
        body: const Center(child: Text('Please sign in to see your liked songs')),
        bottomNavigationBar: BottomBar.bottomAppBar(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Songs'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getLikedSongsStream(currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You haven\'t liked any songs yet.'));
          }

          final songIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return FutureBuilder<List<Song>>(
            future: _firestoreService.getPlaylistSongs(songIds),
            builder: (context, songSnapshot) {
              if (songSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!songSnapshot.hasData || songSnapshot.data!.isEmpty) {
                return const Center(child: Text('Loading songs...'));
              }

              final songs = songSnapshot.data!;

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
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () {
                        _firestoreService.toggleLike(currentUser!.uid, song.id!);
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
          );
        },
      ),
      bottomNavigationBar: BottomBar.bottomAppBar(context),
    );
  }
}
