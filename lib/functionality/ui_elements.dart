import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/screens/lyric_screen.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/news_model.dart';
import 'package:kenoverse/screens/news_article_screen.dart';
import 'package:kenoverse/screens/search_results_screen.dart';
import 'package:kenoverse/functionality/firestore_service.dart';

class News {
  Widget newNews(BuildContext context, NewsArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsArticleScreen(article: article)),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: context.colorScheme.outlineVariant),
          color: context.colorScheme.secondaryContainer,
          borderRadius: context.radiusXL,
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withValues(alpha: 0.2),
              offset: const Offset(4.0, 4.0),
              blurRadius: 10.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              article.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'images/callofsilence.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 15,
              left: 15,
              right: 15,
              child: Text(
                article.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Albums {
  Widget newAlbum(BuildContext context, Song melody) {
    String title = melody.title();
    Image thumbnail = melody.thumbnail()!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LyricScreen(song: melody),
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
                tag: 'song-art-${melody.id}',
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

class KenoSearchBar extends StatelessWidget {
  final Widget child;
  const KenoSearchBar({super.key, required this.child});

  static void open(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SearchDialog();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => open(context), child: child);
  }
}

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<Song> _previews = [];
  bool _isLoading = false;

  void _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() {
        _previews = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final results = await FirestoreService().searchSongs(query);
    if (mounted) {
      setState(() {
        _previews = results.take(5).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  if (val.isNotEmpty) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchResultsScreen(query: val)),
                    );
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colorScheme.surfaceContainerHighest,
                  hintText: 'Search songs, lyrics...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isLoading ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(color: context.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(color: context.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(color: context.colorScheme.primary, width: 1),
                  ),
                ),
              ),
              if (_previews.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: context.radiusMD,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _previews.length,
                    itemBuilder: (context, index) {
                      final song = _previews[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: context.radiusXS,
                          child: Image(image: song.thumbnail()!.image, height: 40, width: 40, fit: BoxFit.cover),
                        ),
                        title: Text(song.title(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(song.songAlbums.join(', '), style: const TextStyle(fontSize: 12), maxLines: 1),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LyricScreen(song: song)));
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: context.radiusMD,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class MiniAlbumViewer extends StatefulWidget {
//   const MiniAlbumViewer({super.key});
//   @override
//   State<MiniAlbumViewer> createState() => _MiniAlbumViewerState();
//
//   class _MiniAlbumViewerState extends State<MiniAlbumViewer> {
//
// }
// }
