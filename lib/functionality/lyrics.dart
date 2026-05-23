// This file defines the core data models for songs, lyrics, and audio versions.
// It handles song metadata, LRC lyric parsing, and serialization.
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'lyrics.g.dart';

/// Represents a single line of lyrics with a starting timestamp.
class LyricLine {
  final Duration startTime;
  final String text;

  LyricLine({required this.startTime, required this.text});
}

/// Represents an alternative audio mix or version of a song (e.g., "Acoustic", "Remix").
@HiveType(typeId: 1)
class AudioVersion {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String? youtubeUrl;
  @HiveField(2)
  final String? spotifyUrl;
  @HiveField(3)
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

/// Represents a specific translation or transliteration of a song's lyrics.
@HiveType(typeId: 2)
class LyricVersion {
  @HiveField(0)
  final String language; // e.g., "English", "Japanese", "Romanized"
  @HiveField(1)
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

/// The primary data model for a Song in KenoVerse.
/// Contains metadata, contributors, streaming links, and lyrics.
@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  String? id; // Firestore document ID
  @HiveField(1)
  late String songTitle;
  @HiveField(2)
  String? songLyrics; // Main/Default lyrics (original language)
  Image? songThumbnail;
  @HiveField(3)
  String? songThumbnailUrl;
  @HiveField(4)
  bool isDraft;
  @HiveField(5)
  String? songLanguage;
  @HiveField(6)
  List<String> songAlbums;
  @HiveField(7)
  DateTime? songReleaseDate;
  @HiveField(8)
  String? songYoutubeUrl;
  @HiveField(9)
  String? songSpotifyUrl;
  @HiveField(10)
  String? songAudioUrl;

  // Multi-artist/Contributor fields
  @HiveField(11)
  List<String> originalArtists;
  @HiveField(12)
  List<String> vocals;
  @HiveField(13)
  List<String> featuredArtists;
  @HiveField(14)
  List<String> audioPreedit;
  @HiveField(15)
  List<String> arrangement;
  @HiveField(16)
  List<String> artworkBy;
  @HiveField(17)
  List<String> videoBy;

  // Lists of alternative versions
  @HiveField(18)
  List<AudioVersion>? audioVersions;
  @HiveField(19)
  List<LyricVersion>? lyricVersions;

  // Local storage fields
  @HiveField(20)
  String? localAudioPath;

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
    this.localAudioPath,
  });

  /// The standard placeholder image used when no thumbnail is available.
  static Image get defaultThumbnail => Image.asset('images/callofsilence.jpg');

  /// Creates a Song object from a Firestore document map.
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
        : defaultThumbnail,
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
      localAudioPath: data['localAudioPath'], // Usually not from Firestore, but included for completeness
    );
  }

  // --- Convenience Getters ---

  String title() => songTitle;
  String? language() => songLanguage;
  List<String> albums() => songAlbums;
  DateTime? releaseDate() => songReleaseDate;
  String? youtubeUrl() => songYoutubeUrl;
  String? spotifyUrl() => songSpotifyUrl;
  Image? thumbnail() => songThumbnail;
  String? lyrics() => songLyrics;

  /// Parses a raw LRC (LyriC) string into a list of [LyricLine] objects.
  /// Expects lines in the format: [mm:ss.xx] Lyric text
  static List<LyricLine> parseLyrics(String lyrics) {
    final List<LyricLine> lines = [];
    // Regex matches [minutes:seconds] followed by the line text.
    // Supports milliseconds/fractions of seconds.
    final RegExp regExp = RegExp(r'\[(\d+):(\d+\.?\d*)\](.*)');

    for (var line in lyrics.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final int minutes = int.parse(match.group(1)!);
        final double seconds = double.parse(match.group(2)!);
        final String text = match.group(3)!.trim();

        // Convert the timestamp groups into a Duration object.
        final Duration startTime = Duration(
          minutes: minutes,
          seconds: seconds.toInt(),
          milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
        );

        lines.add(LyricLine(startTime: startTime, text: text));
      }
    }
    // Ensure the lyrics are sorted by time for accurate scrolling.
    lines.sort((a, b) => a.startTime.compareTo(b.startTime));
    return lines;
  }

  /// Removes all [mm:ss.xx] timestamps from an LRC string, returning plain text.
  static String stripTimestamps(String lyrics) {
    final RegExp regExp = RegExp(r'\[\d+:\d+\.?\d*\]');
    return lyrics.replaceAll(regExp, '').trim();
  }
}
