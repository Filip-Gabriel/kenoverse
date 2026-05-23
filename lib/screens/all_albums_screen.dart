// Displays a complete grid of all available albums/songs in the library.
// Uses a responsive grid layout with a pinned search bar/header.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:provider/provider.dart';
import 'package:kenoverse/functionality/sync_service.dart';
import 'package:kenoverse/screens/lyric_screen.dart';

class AllAlbumsScreen extends StatelessWidget {
  const AllAlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Song>>(
          stream: context.read<SyncService>().getLocalSongsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No albums found',
                  style: TextStyle(color: context.colorScheme.secondary),
                ),
              );
            }
            var songs = snapshot.data!;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: context.colorScheme.surface,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'All Albums',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildGridAlbum(context, songs[index]);
                      },
                      childCount: songs.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: context.radiusMD,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: context.colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
          context.gapSM,
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  song.songAlbums.isNotEmpty ? song.songAlbums.first : 'Single',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
