import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';

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
                      color: Theme.of(context).colorScheme.surfaceContainer,
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
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image(
                                          image: song.thumbnail()!.image,
                                          height: 160,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : Container(
                                        height: 160,
                                        width: 110,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.music_note,
                                          size: 50,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title(),
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                      if (song.album() != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          'ALBUM',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.secondary,
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                        Text(
                                          song.album()!,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ],
                                      if (song.featuredArtist() != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          'ARTIST',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.secondary,
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                        Text(
                                          song.featuredArtist()!,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          if (song.songYoutubeUrl != null)
                                            IconButton.filledTonal(
                                              onPressed: () {}, // TODO: Launch URL
                                              icon: const Icon(Icons.play_circle_fill),
                                              tooltip: 'YouTube',
                                            ),
                                          if (song.songSpotifyUrl != null) ...[
                                            const SizedBox(width: 8),
                                            IconButton.filledTonal(
                                              onPressed: () {}, // TODO: Launch URL
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LYRICS',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            song.lyrics() ?? 'No lyrics available.',
                            style: const TextStyle(fontSize: 16, height: 1.8),
                          ),
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
}
