import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/screens/lyric_screen.dart';

class AllAlbumsScreen extends StatelessWidget {
  const AllAlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().songs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No albums found',
                style: TextStyle(color: context.colorScheme.secondary),
              ),
            );
          }
          var docs = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              Song song = Song.fromFirestore(data, docs[index].id);
              return _buildGridAlbum(context, song);
            },
          );
        },
      ),
      bottomNavigationBar: BottomBar.bottomAppBar(context),
    );
  }

  Widget _buildGridAlbum(BuildContext context, Song song) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LyricScreen(song: song)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: context.colorScheme.outlineVariant),
                borderRadius: context.radiusSM,
              ),
              child: Hero(
                tag: 'song-art-${song.id}',
                child: Image(
                  image: song.thumbnail()!.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            song.title(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
