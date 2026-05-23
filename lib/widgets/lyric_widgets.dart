import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/screens/artist_profile_screen.dart';
import 'package:kenoverse/functionality/firestore_service.dart';

/// A header widget for the Lyric Screen that displays the song's thumbnail,
/// title, and album information, along with an audio version selector.
class LyricHeader extends StatelessWidget {
  final Song song;
  final String activeAudioName;
  final Function(String?) onAudioVersionChanged;
  final Function(String?) onLaunchUrl;
  final VoidCallback? onPlaySynced;
  final String? syncedPlayLabel;
  final bool isPlaying;

  const LyricHeader({
    super.key,
    required this.song,
    required this.activeAudioName,
    required this.onAudioVersionChanged,
    required this.onLaunchUrl,
    this.onPlaySynced,
    this.syncedPlayLabel,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            song.thumbnail() != null
                ? Hero(
                    tag: 'song-art-${song.id}',
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
                  if (song.songAlbums.isNotEmpty) ...[
                    context.gapSM,
                    _buildFieldInfo(context, 'ALBUM', song.songAlbums.join(', ')),
                  ],
                  const SizedBox(height: 12),
                  
                  // Audio Version Selector
                  if (song.audioVersions != null && song.audioVersions!.isNotEmpty) ...[
                    Text('AUDIO VERSION', style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.secondary)),
                    DropdownButton<String>(
                      value: activeAudioName,
                      isDense: true,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                        ...song.audioVersions!.map((v) => DropdownMenuItem(value: v.name, child: Text(v.name))),
                      ],
                      onChanged: onAudioVersionChanged,
                    ),
                  ],

                  context.gapMD,
                  Row(
                    children: [
                      if (onPlaySynced != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onPlaySynced,
                            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                            label: Text(isPlaying ? 'Pause' : (syncedPlayLabel ?? 'Play with MV')),
                          ),
                        )
                      else ...[
                        if (song.songYoutubeUrl != null)
                          IconButton.filledTonal(
                            onPressed: () => onLaunchUrl(song.songYoutubeUrl),
                            icon: const Icon(Icons.play_circle_fill),
                            tooltip: 'YouTube',
                          ),
                        if (song.songSpotifyUrl != null) ...[
                          context.gapSM,
                          IconButton.filledTonal(
                            onPressed: () => onLaunchUrl(song.songSpotifyUrl),
                            icon: const Icon(Icons.library_music),
                            tooltip: 'Spotify',
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
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
}

/// A section that displays categorized credits for a song (e.g., Vocals, Arrangement).
/// Links to artist profiles for each contributor.
class SongCreditsSection extends StatelessWidget {
  final Song song;

  const SongCreditsSection({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
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
      padding: context.paddingVertical(AppConstants.spacingXS),
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
            child: Wrap(
              spacing: AppConstants.spacingSM,
              children: artists.map((name) {
                return InkWell(
                  onTap: () async {
                    final artist = await FirestoreService().getOrCreateArtist(name);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtistProfileScreen(artistId: artist.id),
                        ),
                      );
                    }
                  },
                  child: Text(
                    name + (name == artists.last ? '' : ','),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// The interactive Karaoke view that highlights the current line
/// and scrolls automatically as the song plays.
class KaraokeView extends StatelessWidget {
  final List<LyricLine> parsedLyrics;
  final int currentLineIndex;
  final ScrollController scrollController;

  const KaraokeView({
    super.key,
    required this.parsedLyrics,
    required this.currentLineIndex,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // Fixed height for karaoke display
      child: ListView.builder(
        controller: scrollController,
        itemCount: parsedLyrics.length,
        itemBuilder: (context, index) {
          final line = parsedLyrics[index];
          final isActive = index == currentLineIndex;
          
          return Container(
            height: 60.0, // Optimized height: compact but allows for 2-line wraps
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: AppConstants.durationFast,
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: isActive ? 24 : 18,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive 
                  ? context.colorScheme.primary 
                  : context.colorScheme.onSurface.withValues(alpha: 0.2), // Faded for better focus
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
