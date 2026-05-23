// Implements the global search functionality, including the search dialog.
// Features real-time search previews and navigation to full results.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/screens/lyric_screen.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/screens/search_results_screen.dart';
import 'package:kenoverse/functionality/firestore_service.dart';

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
        padding: EdgeInsets.fromLTRB(
          AppConstants.spacingLG,
          AppConstants.spacingXXL + AppConstants.spacingSM,
          AppConstants.spacingLG,
          AppConstants.spacingLG,
        ),
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
                  contentPadding: context.paddingHorizontal(AppConstants.spacingLG),
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
                context.gapSM,
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: context.radiusMD,
                    boxShadow: [
                      BoxShadow(color: context.colorScheme.shadow.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
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
              context.gapSM,
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
