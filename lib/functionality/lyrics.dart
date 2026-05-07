import 'package:flutter/material.dart';

class LyricLine {
  final Duration startTime;
  final String text;

  LyricLine({required this.startTime, required this.text});
}

class AudioVersion {
  final String name; // e.g., "Original", "Sped Up", "Slowed"
  final String? youtubeUrl;
  final String? spotifyUrl;
  final String? audioUrl;

  AudioVersion({required this.name, this.youtubeUrl, this.spotifyUrl, this.audioUrl});

  factory AudioVersion.fromMap(Map<String, dynamic> data) {
    return AudioVersion(
      name: data['name'] ?? 'Unknown',
      youtubeUrl: data['youtubeUrl'],
      spotifyUrl: data['spotifyUrl'],
      audioUrl: data['audioUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'youtubeUrl': youtubeUrl,
      'spotifyUrl': spotifyUrl,
      'audioUrl': audioUrl,
    };
  }
}

class LyricVersion {
  final String language; // e.g., "English", "Japanese", "Romanized"
  final String lyrics;

  LyricVersion({required this.language, required this.lyrics});

  factory LyricVersion.fromMap(Map<String, dynamic> data) {
    return LyricVersion(
      language: data['language'] ?? 'Unknown',
      lyrics: data['lyrics'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'lyrics': lyrics,
    };
  }
}

class Song {
  String? id; // Firestore document ID
  late String songTitle;
  String? songLyrics; // Main/Default lyrics
  Image? songThumbnail;
  String? songThumbnailUrl;
  bool isDraft;
  String? songLanguage;
  List<String> songAlbums;
  DateTime? songReleaseDate;
  String? songYoutubeUrl;
  String? songSpotifyUrl;
  String? songAudioUrl;

  // Multi-artist fields
  List<String> originalArtists;
  List<String> vocals;
  List<String> featuredArtists;
  List<String> audioPreedit;
  List<String> arrangement;
  List<String> artworkBy;
  List<String> videoBy;

  // Versions
  List<AudioVersion>? audioVersions;
  List<LyricVersion>? lyricVersions;

  Song(
    this.songTitle, {
    this.id,
    this.isDraft = true,
    this.songLanguage,
    this.songAlbums = const [],
    this.songReleaseDate,
    this.songYoutubeUrl,
    this.songSpotifyUrl,
    this.songAudioUrl,
    this.songThumbnail,
    this.songThumbnailUrl,
    this.songLyrics,
    this.originalArtists = const [],
    this.vocals = const [],
    this.featuredArtists = const [],
    this.audioPreedit = const [],
    this.arrangement = const [],
    this.artworkBy = const [],
    this.videoBy = const [],
    this.audioVersions = const [],
    this.lyricVersions = const [],
  });

  factory Song.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Song(
      data['title'] ?? 'Unknown Title',
      id: documentId,
      isDraft: false,
      songLanguage: data['language'],
      songAlbums: List<String>.from(data['albums'] ?? (data['album'] != null ? [data['album']] : [])),
      songReleaseDate: data['releaseDate'] != null ? (data['releaseDate'] as dynamic).toDate() : null,
      songYoutubeUrl: data['youtubeUrl'],
      songSpotifyUrl: data['spotifyUrl'],
      songAudioUrl: data['audioUrl'],
      songLyrics: data['lyrics'],
      songThumbnailUrl: data['thumbnailUrl'],
      songThumbnail: data['thumbnailUrl'] != null 
        ? Image.network(data['thumbnailUrl']) 
        : Image.asset('images/callofsilence.jpg'),
      originalArtists: List<String>.from(data['originalArtists'] ?? []),
      vocals: List<String>.from(data['vocals'] ?? []),
      featuredArtists: List<String>.from(data['featuredArtists'] ?? []),
      audioPreedit: List<String>.from(data['audioPreedit'] ?? []),
      arrangement: List<String>.from(data['arrangement'] ?? []),
      artworkBy: List<String>.from(data['artworkBy'] ?? []),
      videoBy: List<String>.from(data['videoBy'] ?? []),
      audioVersions: (data['audioVersions'] as List? ?? [])
          .map((v) => AudioVersion.fromMap(Map<String, dynamic>.from(v)))
          .toList(),
      lyricVersions: (data['lyricVersions'] as List? ?? [])
          .map((v) => LyricVersion.fromMap(Map<String, dynamic>.from(v)))
          .toList(),
    );
  }

  void addLyrics(String lyrics) {
    songLyrics = lyrics;
  }

  void addThumbnail(Image thumbnail) {
    songThumbnail = thumbnail;
  }

  void markAsPublic() {
    isDraft = false;
  }

  String title() {
    return songTitle;
  }

  String? language() {
    return songLanguage;
  }

  List<String> albums() {
    return songAlbums;
  }

  DateTime? releaseDate() {
    return songReleaseDate;
  }

  String? youtubeUrl() {
    return songYoutubeUrl;
  }

  String? spotifyUrl() {
    return songSpotifyUrl;
  }

  Image? thumbnail() {
    return songThumbnail;
  }

  String? lyrics() {
    return songLyrics;
  }

  static List<LyricLine> parseLyrics(String lyrics) {
    final List<LyricLine> lines = [];
    final RegExp regExp = RegExp(r'\[(\d+):(\d+\.?\d*)\](.*)');

    for (var line in lyrics.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final int minutes = int.parse(match.group(1)!);
        final double seconds = double.parse(match.group(2)!);
        final String text = match.group(3)!.trim();

        final Duration startTime = Duration(
          minutes: minutes,
          seconds: seconds.toInt(),
          milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
        );

        lines.add(LyricLine(startTime: startTime, text: text));
      } else if (line.trim().isNotEmpty) {
        // Handle lines without timestamps if necessary, 
        // maybe treat them as starting at 0 or continuing from previous.
        // For karaoke, we usually ignore untimestamped lines or treat them as info.
      }
    }
    // Sort lines by time just in case
    lines.sort((a, b) => a.startTime.compareTo(b.startTime));
    return lines;
  }

  static String stripTimestamps(String lyrics) {
    // Regex for LRC timestamps: [mm:ss.xx] or [mm:ss]
    final RegExp regExp = RegExp(r'\[\d+:\d+\.?\d*\]');
    return lyrics.replaceAll(regExp, '').trim();
  }
}

Song rightfully = Song(
  'Rightfully',
  isDraft: false,
  songLanguage: 'english',
  songAlbums: ['Rightfully (From ”Goblin Slayer”)'],
  songReleaseDate: DateTime(2018, 12, 15),
  songYoutubeUrl: 'https://youtu.be/-7BmO8Ocdi8',
  songSpotifyUrl:
      'https://open.spotify.com/track/1PPd67Amh9LXCR2u3dS5gk?si=1226d7cfac2f4dec',
  songAudioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  songThumbnail: Image.network(
    'https://i.scdn.co/image/ab67616d0000b27339f55d313059289288f1c0fc',
  ),
  originalArtists: ['Mili'],
  vocals: ['cassie wei'],
  arrangement: ['Yamato Kasai'],
  songLyrics: r'''[00:00.00] [Verse 1]
[00:05.00] Chained onto me
[00:08.00] My adolescent dreams
[00:11.00] Pulling, dragged me deep
[00:14.00] All my body exposed
[00:17.00] Marked up by your shadows

[00:20.00] [Pre-Chorus]
[00:23.00] Tighten up
[00:25.00] Numb your senses
[00:27.00] No fairness is needed for pigs
[00:30.00] Laughters above
[00:32.00] Playful smiles
[00:34.00] Die gets rolled

[00:36.00] [Chorus]
[00:38.00] Bathe in sorrow
[00:40.00] My tomorrow is built upon your flesh
[00:44.00] Slay the last of your kind
[00:47.00] To reclaim what’s rightfully mine
''',
);
