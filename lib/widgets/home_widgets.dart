import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/functionality/news_model.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/widgets/news_card.dart';
import 'package:kenoverse/widgets/song_actions.dart';
import 'package:kenoverse/screens/lyric_screen.dart';

/// The top header of the home screen, providing a personalized greeting
/// and access to the settings dialog.
class HomeWelcomeHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final Widget profileAvatar;

  const HomeWelcomeHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.profileAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingLG,
        AppConstants.spacingLG,
        AppConstants.spacingLG,
        AppConstants.spacingSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.secondary,
                ),
              ),
              Text(
                name,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          profileAvatar,
        ],
      ),
    );
  }
}

/// A horizontally scrolling carousel that displays featured news articles.
class NewsCarousel extends StatelessWidget {
  final List<NewsArticle> articles;

  const NewsCarousel({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.98),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            child: NewsCard(article: articles[index]),
          );
        },
      ),
    );
  }
}

/// A horizontal list showing songs the user has recently interacted with.
class RecentlyAccessedList extends StatelessWidget {
  final List<QueryDocumentSnapshot> historyDocs;

  const RecentlyAccessedList({super.key, required this.historyDocs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: context.paddingHorizontal(AppConstants.spacingLG),
        itemCount: historyDocs.length,
        itemBuilder: (context, index) {
          String songId = historyDocs[index]['songId'];
          return FutureBuilder<DocumentSnapshot>(
            future: FirestoreService().songsCollection.doc(songId).get(),
            builder: (context, songSnapshot) {
              if (!songSnapshot.hasData || !songSnapshot.data!.exists) {
                return const SizedBox();
              }
              var data = songSnapshot.data!.data() as Map<String, dynamic>;
              Song song = Song.fromFirestore(data, songSnapshot.data!.id);
              return _RecentlyAccessedItem(song: song);
            },
          );
        },
      ),
    );
  }
}

class _RecentlyAccessedItem extends StatelessWidget {
  final Song song;
  const _RecentlyAccessedItem({required this.song});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LyricScreen(song: song)),
        );
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: context.radiusMD,
              child: Image(
                image: song.thumbnail()!.image,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            context.gapXS,
            Text(
              song.title(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list tile specifically styled for the 'Recent Releases' section.
class RecentReleaseTile extends StatelessWidget {
  final Song song;

  const RecentReleaseTile({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLG,
        vertical: AppConstants.spacingSM,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LyricScreen(song: song)),
          );
        },
        borderRadius: context.radiusLG,
        child: Container(
          padding: context.paddingMD,
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: context.radiusLG,
            border: Border.all(color: context.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: context.radiusMD,
                child: Image(
                  image: song.thumbnail()!.image,
                  height: 56,
                  width: 56,
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
                      style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      song.songAlbums.isNotEmpty ? song.songAlbums.join(', ') : 'Single',
                      style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: context.colorScheme.onSurfaceVariant,
                onPressed: () => SongActions.showSongMenu(context, song),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
