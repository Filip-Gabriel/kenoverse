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
import 'dart:async';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

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

  // Karaoke State
  bool isKaraokeMode = false; // Whether the lyrics HAVE timestamps
  bool useKaraokeDisplay = false; // User preference: use karaoke view if active
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Duration _currentTime = Duration.zero;
  List<LyricLine> _parsedLyrics = [];
  final ScrollController _scrollController = ScrollController();
  int _currentLineIndex = -1;

  // YouTube Player State
  YoutubePlayerController? _youtubeController;

  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? activeAudioUrl;
  String? localAudioPath;
  String? localAudioName;

  @override
  void initState() {
    super.initState();
    currentLyrics = widget.song.songLyrics ?? 'No lyrics available.';
    currentLanguage = widget.song.songLanguage ?? 'Original';
    activeYoutubeUrl = widget.song.songYoutubeUrl;
    activeSpotifyUrl = widget.song.songSpotifyUrl;
    activeAudioUrl = widget.song.songAudioUrl;
    activeAudioName = 'Standard';

    _parseCurrentLyrics();
    _initYoutubeController();
    _initAudioPlayer();

    // Add to history when song is loaded
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.song.id != null) {
      FirestoreService().addToHistory(user.uid, widget.song.id!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _youtubeController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initYoutubeController() {
    if (activeYoutubeUrl != null) {
      final videoId = YoutubePlayer.convertUrlToId(activeYoutubeUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
      }
    }
  }

  void _initAudioPlayer() async {
    if (localAudioPath != null) {
      try {
        await _audioPlayer.setFilePath(localAudioPath!);
      } catch (e) {
        // Handle error silently or show UI feedback
      }
    } else if (activeAudioUrl != null) {
      try {
        await _audioPlayer.setUrl(activeAudioUrl!);
      } catch (e) {
        // Handle error silently or show UI feedback
      }
    }
  }

  void _pickLocalAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        localAudioPath = result.files.single.path;
        localAudioName = result.files.single.name;
        _resetPlayback();
        _initAudioPlayer();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attached: $localAudioName')),
        );
      }
    }
  }

  void _parseCurrentLyrics() {
    _parsedLyrics = Song.parseLyrics(currentLyrics);
    isKaraokeMode = _parsedLyrics.isNotEmpty;
  }

  void _updateFromSong(Song song) {
    // If the language we are currently looking at exists in the new song data, 
    // update currentLyrics to the latest version.
    if (currentLanguage == (song.songLanguage ?? 'Original')) {
      currentLyrics = song.songLyrics ?? 'No lyrics available.';
    } else {
      final version = song.lyricVersions?.firstWhere(
        (v) => v.language == currentLanguage,
        orElse: () => LyricVersion(language: '', lyrics: ''),
      );
      if (version != null && version.lyrics.isNotEmpty) {
        currentLyrics = version.lyrics;
      }
    }
    _parseCurrentLyrics();
  }

  void _togglePlayback() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _audioPlayer.pause();
        _timer?.cancel();
      } else {
        _stopwatch.start();
        if (localAudioPath != null || activeAudioUrl != null) {
          _audioPlayer.play();
        }
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {
            // Use actual audio position if playing audio, otherwise fallback to stopwatch
            if ((localAudioPath != null || activeAudioUrl != null) && _audioPlayer.position != Duration.zero) {
              _currentTime = _audioPlayer.position;
            } else {
              _currentTime = _stopwatch.elapsed;
            }
            _updateCurrentLine();
          });
        });
      }
    });
  }

  void _resetPlayback() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _audioPlayer.stop();
      _audioPlayer.seek(Duration.zero);
      _currentTime = Duration.zero;
      _currentLineIndex = -1;
      _timer?.cancel();
    });
  }

  void _updateCurrentLine() {
    int index = -1;
    for (int i = 0; i < _parsedLyrics.length; i++) {
      if (_currentTime >= _parsedLyrics[i].startTime) {
        index = i;
      } else {
        break;
      }
    }

    if (index != _currentLineIndex) {
      _currentLineIndex = index;
      if (_currentLineIndex != -1) {
        _scrollToCurrentLine();
      }
    }
  }

  void _scrollToCurrentLine() {
    if (_scrollController.hasClients && _currentLineIndex != -1) {
      _scrollController.animateTo(
        _currentLineIndex * 40.0, // Rough estimate of line height
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildModeSwitcher(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitcherTab(context, 'Standard', !useKaraokeDisplay, () {
            setState(() {
              useKaraokeDisplay = false;
              _resetPlayback();
            });
          }),
          _buildSwitcherTab(context, 'Karaoke', useKaraokeDisplay, () {
            setState(() {
              useKaraokeDisplay = true;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildSwitcherTab(BuildContext context, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: isActive ? 90 : 70, // Active tab is wider
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? context.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive ? [
            BoxShadow(
              color: context.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Center(
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: isActive ? context.colorScheme.onPrimary : context.colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
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

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "${widget.song.title()}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (widget.song.id != null) {
                await FirestoreService().deleteSong(widget.song.id!);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Song deleted successfully')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: context.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().songsCollection.doc(widget.song.id).snapshots(),
      builder: (context, snapshot) {
        Song currentSong = widget.song;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentSong = Song.fromFirestore(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
          // Update the current state if the database changed
          _updateFromSong(currentSong);
        }

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
                                            stream: FirestoreService().isLiked(FirebaseAuth.instance.currentUser!.uid, currentSong.id!),
                                            builder: (context, snapshot) {
                                              bool isLiked = snapshot.data ?? false;
                                              return IconButton(
                                                icon: Icon(
                                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                                  color: isLiked ? Colors.red : null,
                                                ),
                                                tooltip: isLiked ? 'Unlike' : 'Like',
                                                onPressed: () {
                                                  FirestoreService().toggleLike(FirebaseAuth.instance.currentUser!.uid, currentSong.id!);
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
                                                builder: (context) => AddVersionScreen(song: currentSong),
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
                                                builder: (context) => NewSong(existingSong: currentSong),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          tooltip: 'Delete Song',
                                          color: context.colorScheme.error,
                                          onPressed: _showDeleteConfirmationDialog,
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
                                    currentSong.thumbnail() != null
                                        ? Hero(
                                            tag: 'song-art-${currentSong.id}',
                                            child: ClipRRect(
                                              borderRadius: context.radiusSM,
                                              child: Image(
                                                image: currentSong.thumbnail()!.image,
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
                                            currentSong.title(),
                                            style: context.textTheme.headlineSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: context.colorScheme.primary,
                                                ),
                                          ),
                                          if (currentSong.songAlbums.isNotEmpty) ...[
                                            context.gapSM,
                                            _buildFieldInfo(context, 'ALBUM', currentSong.songAlbums.join(', ')),
                                          ],
                                          const SizedBox(height: 12),
                                          
                                          // Audio Version Selector
                                          if (currentSong.audioVersions != null && currentSong.audioVersions!.isNotEmpty) ...[
                                            Text('AUDIO VERSION', style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.secondary)),
                                            DropdownButton<String>(
                                              value: activeAudioName,
                                              isDense: true,
                                              isExpanded: true,
                                              underline: const SizedBox(),
                                              items: [
                                                const DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                                                ...currentSong.audioVersions!.map((v) => DropdownMenuItem(value: v.name, child: Text(v.name))),
                                              ],
                                              onChanged: (val) {
                                                setState(() {
                                                  activeAudioName = val;
                                                  if (val == 'Standard') {
                                                    activeYoutubeUrl = currentSong.songYoutubeUrl;
                                                    activeSpotifyUrl = currentSong.songSpotifyUrl;
                                                    activeAudioUrl = currentSong.songAudioUrl;
                                                  } else {
                                                    final version = currentSong.audioVersions!.firstWhere((v) => v.name == val);
                                                    activeYoutubeUrl = version.youtubeUrl ?? currentSong.songYoutubeUrl;
                                                    activeSpotifyUrl = version.spotifyUrl ?? currentSong.songSpotifyUrl;
                                                    activeAudioUrl = version.audioUrl ?? currentSong.songAudioUrl;
                                                  }
                                                  _initAudioPlayer();
                                                  _resetPlayback();
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
                                            ),
                                      ),
                                      if (isKaraokeMode) ...[
                                        context.gapMD,
                                        _buildModeSwitcher(context),
                                      ],
                                    ],
                                  ),
                                  // Lyric Language Selector
                                  if (currentSong.lyricVersions != null && currentSong.lyricVersions!.isNotEmpty)
                                    DropdownButton<String>(
                                      value: currentLanguage,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      items: [
                                        DropdownMenuItem(value: currentSong.songLanguage ?? 'Original', child: Text(currentSong.songLanguage ?? 'Original')),
                                        ...currentSong.lyricVersions!.map((v) => DropdownMenuItem(value: v.language, child: Text(v.language))),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          currentLanguage = val!;
                                          if (val == (currentSong.songLanguage ?? 'Original')) {
                                            currentLyrics = currentSong.songLyrics ?? 'No lyrics available.';
                                          } else {
                                            currentLyrics = currentSong.lyricVersions!.firstWhere((v) => v.language == val).lyrics;
                                          }
                                          _parseCurrentLyrics();
                                          _resetPlayback();
                                        });
                                      },
                                    ),
                                ],
                              ),
                              if (isKaraokeMode && useKaraokeDisplay) ...[
                                context.gapMD,
                                Row(
                                  children: [
                                    IconButton.filledTonal(
                                      onPressed: _togglePlayback,
                                      icon: Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      onPressed: _resetPlayback,
                                      icon: const Icon(Icons.replay),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      onPressed: _pickLocalAudio,
                                      icon: Icon(localAudioPath != null ? Icons.audio_file : Icons.attach_file),
                                      tooltip: localAudioPath != null ? 'Change Local Audio' : 'Attach Local Audio',
                                      visualDensity: VisualDensity.compact,
                                      color: localAudioPath != null ? context.colorScheme.primary : null,
                                    ),
                                    if (localAudioName != null)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            localAudioName!,
                                            style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.secondary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              context.gapLG,
                              if (isKaraokeMode && useKaraokeDisplay)
                                SizedBox(
                                  height: 400, // Fixed height for karaoke display
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _parsedLyrics.length,
                                    itemBuilder: (context, index) {
                                      final line = _parsedLyrics[index];
                                      final isActive = index == _currentLineIndex;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(
                                          line.text,
                                          style: TextStyle(
                                            fontSize: isActive ? 22 : 18,
                                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                            color: isActive 
                                              ? context.colorScheme.primary 
                                              : context.colorScheme.onSurface.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                Text(
                                  Song.stripTimestamps(currentLyrics),
                                  style: const TextStyle(fontSize: 16, height: 1.8),
                                ),
                              
                              if (activeYoutubeUrl != null && _youtubeController != null) ...[
                                context.gapXL,
                                Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline,
                                      size: 20,
                                      color: context.colorScheme.primary,
                                    ),
                                    context.gapSM,
                                    Text(
                                      'Music Video',
                                      style: context.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2.0,
                                            color: context.colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                                context.gapMD,
                                ClipRRect(
                                  borderRadius: context.radiusMD,
                                  child: YoutubePlayer(
                                    controller: _youtubeController!,
                                    showVideoProgressIndicator: true,
                                    progressIndicatorColor: context.colorScheme.primary,
                                  ),
                                ),
                              ],

                              context.gapXL,
                              const Divider(),
                              context.gapMD,
                              // Credits Section
                              _buildCreditsSection(context, currentSong),
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
      },
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

  Widget _buildCreditsSection(BuildContext context, Song song) {
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
