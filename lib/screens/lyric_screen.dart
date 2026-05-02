import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/screens/new_song_screen.dart';
import 'package:kenoverse/screens/add_version_screen.dart';
import 'package:kenoverse/screens/artist_profile_screen.dart';
import 'package:kenoverse/functionality/playlist_model.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LyricScreen extends StatefulWidget {
  final Song song;
  const LyricScreen({super.key, required this.song});

  @override
  State<LyricScreen> createState() => _LyricScreenState();
}

class _LyricScreenState extends State<LyricScreen> {
  late String currentLyrics;
  late String currentLanguage;
  
  String? activeYoutubeUrl;
  String? activeSpotifyUrl;
  String? activeAudioName;

  @override
  void initState() {
    super.initState();
    currentLyrics = widget.song.songLyrics ?? 'No lyrics available.';
    currentLanguage = widget.song.songLanguage ?? 'Original';
    activeYoutubeUrl = widget.song.songYoutubeUrl;
    activeSpotifyUrl = widget.song.songSpotifyUrl;
    activeAudioName = 'Standard';
  }

  void _launchURL(String? urlString) async {
    if (urlString == null) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showAddToPlaylistDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to add to playlist')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getUserPlaylists(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Text('No playlists found. Create one to get started.');

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final playlist = Playlist.fromFirestore(snapshot.data!.docs[index]);
                  final isAlreadyAdded = playlist.songIds.contains(widget.song.id);
                  
                  return ListTile(
                    title: Text(playlist.name),
                    trailing: isAlreadyAdded ? Icon(Icons.check_circle, color: context.colorScheme.primary) : null,
                    subtitle: isAlreadyAdded ? const Text('Already added') : null,
                    onTap: isAlreadyAdded ? null : () async {
                      await FirestoreService().addSongToPlaylist(playlist.id, widget.song.id!);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to ${playlist.name}')));
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

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
                            padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Row(
                                  children: [
                                    if (FirebaseAuth.instance.currentUser != null)
                                      StreamBuilder<bool>(
                                        stream: FirestoreService().isLiked(FirebaseAuth.instance.currentUser!.uid, widget.song.id!),
                                        builder: (context, snapshot) {
                                          bool isLiked = snapshot.data ?? false;
                                          return IconButton(
                                            icon: Icon(
                                              isLiked ? Icons.favorite : Icons.favorite_border,
                                              color: isLiked ? Colors.red : null,
                                            ),
                                            tooltip: isLiked ? 'Unlike' : 'Like',
                                            onPressed: () {
                                              FirestoreService().toggleLike(FirebaseAuth.instance.currentUser!.uid, widget.song.id!);
                                            },
                                          );
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.playlist_add),
                                      tooltip: 'Add to Playlist',
                                      onPressed: _showAddToPlaylistDialog,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      tooltip: 'Add Version',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddVersionScreen(song: widget.song),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NewSong(existingSong: widget.song),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                widget.song.thumbnail() != null
                                    ? Hero(
                                        tag: 'song-art-${widget.song.id}',
                                        child: ClipRRect(
                                          borderRadius: context.radiusSM,
                                          child: Image(
                                            image: widget.song.thumbnail()!.image,
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
                                        widget.song.title(),
                                        style: context.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: context.colorScheme.primary,
                                            ),
                                      ),
                                      if (widget.song.songAlbums.isNotEmpty) ...[
                                        context.gapSM,
                                        _buildFieldInfo(context, 'ALBUM', widget.song.songAlbums.join(', ')),
                                      ],
                                      const SizedBox(height: 12),
                                      
                                      // Audio Version Selector
                                      if (widget.song.audioVersions != null && widget.song.audioVersions!.isNotEmpty) ...[
                                        Text('AUDIO VERSION', style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.secondary)),
                                        DropdownButton<String>(
                                          value: activeAudioName,
                                          isDense: true,
                                          isExpanded: true,
                                          underline: const SizedBox(),
                                          items: [
                                            const DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                                            ...widget.song.audioVersions!.map((v) => DropdownMenuItem(value: v.name, child: Text(v.name))),
                                          ],
                                          onChanged: (val) {
                                            setState(() {
                                              activeAudioName = val;
                                              if (val == 'Standard') {
                                                activeYoutubeUrl = widget.song.songYoutubeUrl;
                                                activeSpotifyUrl = widget.song.songSpotifyUrl;
                                              } else {
                                                final version = widget.song.audioVersions!.firstWhere((v) => v.name == val);
                                                activeYoutubeUrl = version.youtubeUrl ?? widget.song.songYoutubeUrl;
                                                activeSpotifyUrl = version.spotifyUrl ?? widget.song.songSpotifyUrl;
                                              }
                                            });
                                          },
                                        ),
                                      ],

                                      context.gapMD,
                                      Row(
                                        children: [
                                          if (activeYoutubeUrl != null)
                                            IconButton.filledTonal(
                                              onPressed: () => _launchURL(activeYoutubeUrl),
                                              icon: const Icon(Icons.play_circle_fill),
                                              tooltip: 'YouTube',
                                            ),
                                          if (activeSpotifyUrl != null) ...[
                                            context.gapSM,
                                            IconButton.filledTonal(
                                              onPressed: () => _launchURL(activeSpotifyUrl),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              // Lyric Language Selector
                              if (widget.song.lyricVersions != null && widget.song.lyricVersions!.isNotEmpty)
                                DropdownButton<String>(
                                  value: currentLanguage,
                                  isDense: true,
                                  underline: const SizedBox(),
                                  items: [
                                    DropdownMenuItem(value: widget.song.songLanguage ?? 'Original', child: Text(widget.song.songLanguage ?? 'Original')),
                                    ...widget.song.lyricVersions!.map((v) => DropdownMenuItem(value: v.language, child: Text(v.language))),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      currentLanguage = val!;
                                      if (val == (widget.song.songLanguage ?? 'Original')) {
                                        currentLyrics = widget.song.songLyrics ?? 'No lyrics available.';
                                      } else {
                                        currentLyrics = widget.song.lyricVersions!.firstWhere((v) => v.language == val).lyrics;
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                          context.gapLG,
                          Text(
                            currentLyrics,
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
    
    if (widget.song.originalArtists.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Original Artist', widget.song.originalArtists));
    }
    if (widget.song.vocals.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Vocals', widget.song.vocals));
    }
    if (widget.song.featuredArtists.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Featured', widget.song.featuredArtists));
    }
    if (widget.song.audioPreedit.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Audio/Mix', widget.song.audioPreedit));
    }
    if (widget.song.arrangement.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Arrangement', widget.song.arrangement));
    }
    if (widget.song.artworkBy.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Artwork', widget.song.artworkBy));
    }
    if (widget.song.videoBy.isNotEmpty) {
      credits.add(_buildCreditRow(context, 'Video', widget.song.videoBy));
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
            child: Wrap(
              spacing: 8,
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
