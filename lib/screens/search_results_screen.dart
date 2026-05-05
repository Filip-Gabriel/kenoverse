import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/screens/lyric_screen.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "$query"'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Song>>(
        future: FirestoreService().searchSongs(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.grey),
                  context.gapMD,
                  const Text('No results found.'),
                ],
              ),
            );
          }

          final results = snapshot.data!;

          return ListView.builder(
            padding: context.paddingMD,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final song = results[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LyricScreen(song: song)),
                    );
                  },
                  borderRadius: context.radiusMD,
                  child: Container(
                    padding: context.paddingSM,
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: context.radiusMD,
                      border: Border.all(color: context.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: context.radiusSM,
                          child: Image(
                            image: song.thumbnail()!.image,
                            height: 60,
                            width: 60,
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                song.songAlbums.isNotEmpty ? song.songAlbums.join(', ') : 'Single',
                                style: TextStyle(color: context.colorScheme.secondary, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomBar.bottomAppBar(context),
    );
  }
}
