import 'dart:ui';

class Song {
  late String lyrics;
  late Image thumbnail;

  void addLyrics(String lyrics) {
    this.lyrics = lyrics;
  }
  void addThumbnail(Image thumbnail) {
    this.thumbnail = thumbnail;
  }
}
