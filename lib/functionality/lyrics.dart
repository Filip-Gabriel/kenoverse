import 'package:flutter/material.dart';

class Song {
  late String title;
  String? lyrics;
  Image? thumbnail;
  bool isDraft;
  String? language;
  String? album;

  // New fields
  DateTime? releaseDate;
  String? featuredArtist;
  String? youtubeUrl;
  String? spotifyUrl;

  Song(
    this.title, {
    this.isDraft = true,
    this.language,
    this.album,
    this.releaseDate,
    this.featuredArtist,
    this.youtubeUrl,
    this.spotifyUrl,
    this.thumbnail,
    this.lyrics,
  });

  void addLyrics(String lyrics) {
    this.lyrics = lyrics;
  }

  void addThumbnail(Image thumbnail) {
    this.thumbnail = thumbnail;
  }

  void markAsPublic() {
    isDraft = false;
  }
}

Song rightfully = Song(
  'Rightfully',
  isDraft: false,
  language: 'english',
  album: 'Rightfully (From ”Goblin Slayer”)',
  releaseDate: DateTime(2018, 12, 15),
  featuredArtist: 'IDN/A',
  youtubeUrl: 'https://youtu.be/-7BmO8Ocdi8',
  spotifyUrl: 'https://open.spotify.com/track/1PPd67Amh9LXCR2u3dS5gk?si=1226d7cfac2f4dec',
  thumbnail: Image.network('https://i.scdn.co/image/ab67616d0000b27339f55d313059289288f1c0fc'),
  lyrics: r'''[Verse 1]
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
