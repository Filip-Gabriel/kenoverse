import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';

class LyricScreen extends StatelessWidget {
  final Song song;

  const LyricScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: context.colorScheme.surfaceContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                song.thumbnail() != null
                                    ? Hero(
                                        tag: 'song-art-${song.title()}',
                                        child: ClipRRect(
                                          borderRadius: context.radiusSM,
                                          child: Image(
                                            image: song.thumbnail()!.image,
                                            height: 160,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        height: 160,
                                        width: 110,
                                        decoration: BoxDecoration(
                                          color: context.colorScheme.surface,
                                          borderRadius: context.radiusSM,
                                        ),
                                        child: Icon(
                                          Icons.music_note,
                                          size: 50,
                                          color: context.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                context.gapMD,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title(),
                                        style: context.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: context.colorScheme.primary,
                                            ),
                                      ),
                                      if (song.album() != null) ...[
                                        context.gapSM,
                                        _buildFieldInfo(context, 'ALBUM', song.album()!),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          if (song.songYoutubeUrl != null)
                                            IconButton.filledTonal(
                                              onPressed: () async {
                                                final Uri url = Uri.parse(song.songYoutubeUrl!);
                                                if (!await launchUrl(url)) {
                                                  throw Exception('Could not launch $url');
                                                }
                                              },
                                              icon: const Icon(Icons.play_circle_fill),
                                              tooltip: 'YouTube',
                                            ),
                                          if (song.songSpotifyUrl != null) ...[
                                            context.gapSM,
                                            IconButton.filledTonal(
                                              onPressed: () async {
                                                final Uri url = Uri.parse(song.songSpotifyUrl!);
                                                if (!await launchUrl(url)) {
                                                  throw Exception('Could not launch $url');
                                                }
                                              },
                                              icon: const Icon(Icons.library_music),
                                              tooltip: 'Spotify',
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lyrics_outlined,
                                size: 20,
                                color: context.colorScheme.primary,
                              ),
                              context.gapSM,
                              Text(
                                'LYRICS',
                                style: context.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      color: context.colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          context.gapLG,
                          Text(
                            song.lyrics() ?? 'No lyrics available.',
                            style: const TextStyle(fontSize: 16, height: 1.8),
                          ),
                          context.gapXL,
                          const Divider(),
                          context.gapMD,
                          // Credits Section
                          _buildCreditsSection(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BottomBar.bottomAppBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldInfo(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.secondary,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: context.textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildCreditsSection(BuildContext context) {
    List<Widget> credits = [];
    
    if (song.originalArtists.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Original Artist', song.originalArtists));
    }
    if (song.vocals.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Vocals', song.vocals));
    }
    if (song.featuredArtists.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Featured', song.featuredArtists));
    }
    if (song.audioPreedit.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Audio/Mix', song.audioPreedit));
    }
    if (song.arrangement.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Arrangement', song.arrangement));
    }
    if (song.artworkBy.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Artwork', song.artworkBy));
    }
    if (song.videoBy.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Video', song.videoBy));
    }

    if (credits.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CREDITS',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: context.colorScheme.primary,
            ),
          ),
          context.gapSM,
          ...credits,
        ],
      ),
    );
  }

  Widget _buildCreditRow(BuildContext context, String label, List<String> artists) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              artists.join(', '),
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
