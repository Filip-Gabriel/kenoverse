import 'package:flutter/material.dart';

class Song {
  late String songTitle;
  String? songLyrics;
  Image? songThumbnail;
  bool isDraft;
  String? songLanguage;
  String? songAlbum;
  DateTime? songReleaseDate;
  String? songFeaturedArtist;
  String? songYoutubeUrl;
  String? songSpotifyUrl;

  Song(
    this.songTitle, {
    this.isDraft = true,
    this.songLanguage,
    this.songAlbum,
    this.songReleaseDate,
    this.songFeaturedArtist,
    this.songYoutubeUrl,
    this.songSpotifyUrl,
    this.songThumbnail,
    this.songLyrics,
  });

  factory Song.fromFirestore(Map<String, dynamic> data) {
    return Song(
      data['title'] ?? 'Unknown Title',
      isDraft: false,
      songLanguage: data['language'],
      songAlbum: data['album'],
      songReleaseDate: data['releaseDate'] != null ? (data['releaseDate'] as dynamic).toDate() : null,
      songFeaturedArtist: data['artist'],
      songYoutubeUrl: data['youtubeUrl'],
      songSpotifyUrl: data['spotifyUrl'],
      songLyrics: data['lyrics'],
      songThumbnail: data['thumbnailUrl'] != null 
        ? Image.network(data['thumbnailUrl']) 
        : Image.asset('images/callofsilence.jpg'), // Default placeholder
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

  String? album() {
    return songAlbum;
  }

  DateTime? releaseDate() {
    return songReleaseDate;
  }

  String? featuredArtist() {
    return songFeaturedArtist;
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
  songAlbum: 'Rightfully (From ”Goblin Slayer”)',
  songReleaseDate: DateTime(2018, 12, 15),
  songFeaturedArtist: 'IDN/A',
  songYoutubeUrl: 'https://youtu.be/-7BmO8Ocdi8',
  songSpotifyUrl:
      'https://open.spotify.com/track/1PPd67Amh9LXCR2u3dS5gk?si=1226d7cfac2f4dec',
  songThumbnail: Image.network(
    'https://i.scdn.co/image/ab67616d0000b27339f55d313059289288f1c0fc',
  ),
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
