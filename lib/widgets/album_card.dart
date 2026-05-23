// A compact widget for displaying a song's thumbnail and title.
// Commonly used in horizontal scrolling lists like the 'Albums' section.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/screens/lyric_screen.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';

class AlbumCard extends StatelessWidget {
  final Song song;

  const AlbumCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    String title = song.title();
    Image thumbnail = song.thumbnail()!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LyricScreen(song: song),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;

              var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

              return FadeTransition(
                opacity: animation.drive(fadeTween),
                child: SlideTransition(
                  position: animation.drive(slideTween),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: context.radiusSM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                border: Border.all(color: context.colorScheme.outlineVariant),
                borderRadius: context.radiusXS,
              ),
              child: Hero(
                tag: 'song-art-${song.id}',
                child: Image(image: thumbnail.image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
