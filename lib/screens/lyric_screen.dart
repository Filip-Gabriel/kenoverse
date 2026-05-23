// The main song viewing experience.
// Displays song details, credits, and lyrics with support for multiple languages.
// Features a Karaoke mode with synchronized lyric scrolling and an integrated YouTube player.
import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/screens/new_song_screen.dart';
import 'package:kenoverse/screens/add_version_screen.dart';
import 'package:kenoverse/functionality/playlist_model.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kenoverse/widgets/lyric_widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  // Connectivity State
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
  bool _isSyncedWithYoutube = false;

  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? activeAudioUrl;

  bool get _isPlaying {
    if (_isSyncedWithYoutube) {
      return _youtubeController?.value.isPlaying ?? false;
    } else {
      return _audioPlayer.playing;
    }
  }

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
    _initConnectivity();

    // Listen to local audio player changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() {});
    });

    // Add to history when song is loaded
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.song.id != null) {
      FirestoreService().addToHistory(user.uid, widget.song.id!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    _scrollController.dispose();
    _youtubeController?.removeListener(_youtubeListener);
    _youtubeController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _isOnline = results.any((result) => result != ConnectivityResult.none);
      });
    });

    // Initial check
    Connectivity().checkConnectivity().then((results) {
      setState(() {
        _isOnline = results.any((result) => result != ConnectivityResult.none);
      });
    });
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
        )..addListener(_youtubeListener);
      }
    }
  }

  void _youtubeListener() {
    if (_isSyncedWithYoutube && _youtubeController != null) {
      setState(() {
        if (_youtubeController!.value.isPlaying) {
          _currentTime = _youtubeController!.value.position;
          _updateCurrentLine();
        }
      });
    }
  }

  /// Handles synchronized playback, switching between YouTube (online)
  /// and local file playback (offline).
  void _startSyncedPlayback() async {
    if (_isOnline) {
      if (_youtubeController == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('YouTube player not ready or no video available.')),
        );
        return;
      }
      
      if (_isSyncedWithYoutube && _youtubeController!.value.isPlaying) {
        _youtubeController!.pause();
      } else {
        setState(() {
          if (!_isSyncedWithYoutube) _resetPlayback(); 
          _isSyncedWithYoutube = true;
          useKaraokeDisplay = true;
          _youtubeController!.play();
        });
      }
    } else {
      // Offline fallback: Play local file or pick one
      if (widget.song.localAudioPath != null && File(widget.song.localAudioPath!).existsSync()) {
        if (!_isSyncedWithYoutube && _audioPlayer.playing) {
          _audioPlayer.pause();
          _stopwatch.stop();
          _timer?.cancel();
        } else {
          setState(() {
            if (_isSyncedWithYoutube) _resetPlayback();
            useKaraokeDisplay = true;
            _togglePlayback(); 
          });
        }
      } else {
        // Allow picking a file manually if not already present
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
        if (result != null && result.files.single.path != null) {
          final newPath = result.files.single.path!;
          setState(() {
            _resetPlayback();
            widget.song.localAudioPath = newPath;
            useKaraokeDisplay = true;
          });
          // Persist the choice
          await widget.song.save();
          _initAudioPlayer();
          _togglePlayback();
        }
      }
    }
  }

  void _initAudioPlayer() async {
    if (widget.song.localAudioPath != null && File(widget.song.localAudioPath!).existsSync()) {
      try {
        await _audioPlayer.setFilePath(widget.song.localAudioPath!);
      } catch (e) {
        // Handle error silently
      }
    } else if (activeAudioUrl != null) {
      try {
        await _audioPlayer.setUrl(activeAudioUrl!);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _parseCurrentLyrics() {
    _parsedLyrics = Song.parseLyrics(currentLyrics);
    isKaraokeMode = _parsedLyrics.isNotEmpty;
  }

  void _updateFromSong(Song song) {
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
      _isSyncedWithYoutube = false; 
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _audioPlayer.pause();
        _timer?.cancel();
      } else {
        _stopwatch.start();
        if (activeAudioUrl != null || widget.song.localAudioPath != null) {
          _audioPlayer.play();
        }
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {
            if (_audioPlayer.position != Duration.zero) {
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
      _isSyncedWithYoutube = false;
      _stopwatch.stop();
      _stopwatch.reset();
      _audioPlayer.stop();
      _audioPlayer.seek(Duration.zero);
      _currentTime = Duration.zero;
      _currentLineIndex = -1;
      _timer?.cancel();
      _youtubeController?.pause();
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
      // Calculate offset to center the current line within the container
      // Matching the 60.0 height set in KaraokeView
      const double viewportHeight = 400.0;
      const double itemHeight = 60.0;
      final double centerOffset = (viewportHeight / 2) - (itemHeight / 2);
      
      final double targetOffset = (_currentLineIndex * itemHeight) - centerOffset;

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: AppConstants.durationNormal,
        curve: Curves.easeInOut,
      );
    }
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
              if (snapshot.data!.docs.isEmpty) return const Text('No playlists found.');

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
        content: Text('Are you sure you want to delete "${widget.song.title()}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (widget.song.id != null) {
                await FirestoreService().deleteSong(widget.song.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song deleted successfully')));
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

  bool _shouldShowPCUI(BuildContext context) {
    if (kIsWeb) return true;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return true;
    return MediaQuery.of(context).size.width > AppConstants.breakpointMobile;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPC = _shouldShowPCUI(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreService().songsCollection.doc(widget.song.id).snapshots(),
      builder: (context, snapshot) {
        Song currentSong = widget.song;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentSong = Song.fromFirestore(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
          _updateFromSong(currentSong);
        }

        return Scaffold(
          body: SafeArea(
            child: isPC 
              ? _buildPCLayout(context, currentSong)
              : _buildMobileLayout(context, currentSong),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, Song currentSong) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopToolbar(context, currentSong),
                LyricHeader(
                  song: currentSong,
                  activeAudioName: activeAudioName ?? 'Standard',
                  syncedPlayLabel: _isOnline ? 'Play with MV' : 'Play with File',
                  onAudioVersionChanged: (val) {
                    setState(() {
                      activeAudioName = val;
                      if (val == 'Standard') {
                        activeAudioUrl = currentSong.songAudioUrl;
                      } else {
                        final version = currentSong.audioVersions!.firstWhere((v) => v.name == val);
                        activeAudioUrl = version.audioUrl ?? currentSong.songAudioUrl;
                      }
                      _initAudioPlayer();
                      _resetPlayback();
                    });
                  },
                  onLaunchUrl: _launchURL,
                  onPlaySynced: isKaraokeMode ? _startSyncedPlayback : null,
                  isPlaying: _isPlaying,
                ),
                _buildLyricContent(context, currentSong),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPCLayout(BuildContext context, Song currentSong) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopToolbar(context, currentSong),
                LyricHeader(
                  song: currentSong,
                  activeAudioName: activeAudioName ?? 'Standard',
                  syncedPlayLabel: _isOnline ? 'Play with MV' : 'Play with File',
                  onAudioVersionChanged: (val) {
                    setState(() {
                      activeAudioName = val;
                      if (val == 'Standard') {
                        activeAudioUrl = currentSong.songAudioUrl;
                      } else {
                        final version = currentSong.audioVersions!.firstWhere((v) => v.name == val);
                        activeAudioUrl = version.audioUrl ?? currentSong.songAudioUrl;
                      }
                      _initAudioPlayer();
                      _resetPlayback();
                    });
                  },
                  onLaunchUrl: _launchURL,
                  onPlaySynced: isKaraokeMode ? _startSyncedPlayback : null,
                  isPlaying: _isPlaying,
                ),
                if (_isOnline && activeYoutubeUrl != null && _youtubeController != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.play_circle_outline, size: 20, color: context.colorScheme.primary),
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
                        context.gapMD,
                        _buildMVLinkTiles(context, currentSong),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SongCreditsSection(song: currentSong),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildLyricContent(context, currentSong),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopToolbar(BuildContext context, Song currentSong) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          Row(
            children: [
              if (FirebaseAuth.instance.currentUser != null)
                StreamBuilder<bool>(
                  stream: FirestoreService().isLiked(FirebaseAuth.instance.currentUser!.uid, currentSong.id!),
                  builder: (context, snapshot) {
                    bool isLiked = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? context.colorScheme.error : null),
                      tooltip: isLiked ? 'Unlike' : 'Like',
                      onPressed: () => FirestoreService().toggleLike(FirebaseAuth.instance.currentUser!.uid, currentSong.id!),
                    );
                  },
                ),
              IconButton(icon: const Icon(Icons.playlist_add), tooltip: 'Add to Playlist', onPressed: _showAddToPlaylistDialog),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Version',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddVersionScreen(song: currentSong))),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NewSong(existingSong: currentSong))),
              ),
              IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete Song', color: context.colorScheme.error, onPressed: _showDeleteConfirmationDialog),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLyricContent(BuildContext context, Song currentSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        context.gapMD,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.lyrics_outlined, size: 20, color: context.colorScheme.primary),
                context.gapSM,
                Text('LYRICS', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              ],
            ),
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
        context.gapLG,
        if (isKaraokeMode && useKaraokeDisplay) ...[


          KaraokeView(parsedLyrics: _parsedLyrics, currentLineIndex: _currentLineIndex, scrollController: _scrollController),
        ] else
          Text(Song.stripTimestamps(currentLyrics), style: const TextStyle(fontSize: 16, height: 1.8)),
        
        if (_isOnline && MediaQuery.of(context).size.width <= AppConstants.breakpointMobile) ...[
          if (activeYoutubeUrl != null && _youtubeController != null) ...[
            context.gapXL,
            Row(
              children: [
                Icon(Icons.play_circle_outline, size: 20, color: context.colorScheme.primary),
                context.gapSM,
                Text('Music Video', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2.0, color: context.colorScheme.primary)),
              ],
            ),
            context.gapMD,
            ClipRRect(
              borderRadius: context.radiusMD,
              child: YoutubePlayer(controller: _youtubeController!, showVideoProgressIndicator: true, progressIndicatorColor: context.colorScheme.primary),
            ),
            context.gapMD,
            _buildMVLinkTiles(context, currentSong),
          ],
          context.gapXL,
          const Divider(),
          context.gapMD,
          SongCreditsSection(song: currentSong),
        ],
      ],
    );
  }

  Widget _buildMVLinkTiles(BuildContext context, Song song) {
    return Column(
      children: [
        if (song.songYoutubeUrl != null)
          ListTile(
            leading: const Icon(Icons.play_circle_filled, color: Colors.red),
            title: const Text('Open YouTube'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchURL(song.songYoutubeUrl),
            shape: RoundedRectangleBorder(borderRadius: context.radiusMD),
            tileColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        if (song.songSpotifyUrl != null) ...[
          context.gapSM,
          ListTile(
            leading: const Icon(Icons.library_music, color: Colors.green),
            title: const Text('Add to Spotify'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchURL(song.songSpotifyUrl),
            shape: RoundedRectangleBorder(borderRadius: context.radiusMD),
            tileColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        ],
      ],
    );
  }
}
