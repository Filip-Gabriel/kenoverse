import 'package:flutter/material.dart';

class AudioVersion {
  final String name; // e.g., "Original", "Sped Up", "Slowed"
  final String? youtubeUrl;
  final String? spotifyUrl;

  AudioVersion({required this.name, this.youtubeUrl, this.spotifyUrl});

  factory AudioVersion.fromMap(Map<String, dynamic> data) {
    return AudioVersion(
      name: data['name'] ?? 'Unknown',
      youtubeUrl: data['youtubeUrl'],
      spotifyUrl: data['spotifyUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'youtubeUrl': youtubeUrl,
      'spotifyUrl': spotifyUrl,
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
  songThumbnail: Image.network(
    'https://i.scdn.co/image/ab67616d0000b27339f55d313059289288f1c0fc',
  ),
  originalArtists: ['Mili'],
  vocals: ['cassie wei'],
  arrangement: ['Yamato Kasai'],
  songLyrics: r'''[Verse 1]
Chained onto me
My adolescent dreams
Pulling, dragged me deep
All my body exposed
Marked up by your shadows

[Pre-Chorus]
Tighten up
Numb your senses
No fairness is needed for pigs
Laughters above
Playful smiles
Die gets rolled

[Chorus]
Bathe in sorrow
My tomorrow is built upon your flesh
Slay the last of your kind
To reclaim what’s rightfully mine

[Post-Chorus]
Each time we'll enter
First time to make this
Final dungeon
無念な未来の
I have a reason
Don’t part the rivers
Surround them off with their heads
Christen my motive
First time to notice
Final dungeon
蒸れてまようわ
I hide among you
Facing the fire
{?}

[Verse 2]
I still dream of you
Will you be disappointed that I’m not who I used to be
Will you hold me tightly

[Verse 1]
Chained onto me
My adolescent dreams
Pulling, dragged me deep
All my body exposed
Marked up by your shadows

[Verse 3]
Piece by piece the tables turn and turn again
In this eternal game
Biscuits with clotted cream and milk tea
Time to roll your d-20
Gods nor demons ready to admit defeat

[Pre-Chorus]
Eat up
Grind your teeth
They’re not that much smarter than us
Laughter's above
Playful smiles
Die gets rolled

[Chorus]
Swallow your fate
Lubricate our blades with blood and tears
And your piercing screams are music to celebrate
Infiltrate, penetrate
Soon we’ll have you destroyed
Back to the old days
Slay the last of your kind
To reclaim what’s rightfully mine

[Post-Chorus]
Each time we'll enter
First time to make this
Final dungeon
無念な未来の
I have a reason
Don’t part the rivers
Surround them off with their heads
Christen my motive
First time to notice
Final dungeon
蒸れてまようわ
I hide among you
Facing my fire
At night I’m dreaming
願い夢の言の葉わ''',
);
