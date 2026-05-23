// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioVersionAdapter extends TypeAdapter<AudioVersion> {
  @override
  final int typeId = 1;

  @override
  AudioVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioVersion(
      name: fields[0] as String,
      youtubeUrl: fields[1] as String?,
      spotifyUrl: fields[2] as String?,
      audioUrl: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AudioVersion obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.youtubeUrl)
      ..writeByte(2)
      ..write(obj.spotifyUrl)
      ..writeByte(3)
      ..write(obj.audioUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioVersionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LyricVersionAdapter extends TypeAdapter<LyricVersion> {
  @override
  final int typeId = 2;

  @override
  LyricVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricVersion(
      language: fields[0] as String,
      lyrics: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LyricVersion obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.language)
      ..writeByte(1)
      ..write(obj.lyrics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricVersionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      fields[1] as String,
      id: fields[0] as String?,
      isDraft: fields[4] as bool,
      songLanguage: fields[5] as String?,
      songAlbums: (fields[6] as List).cast<String>(),
      songReleaseDate: fields[7] as DateTime?,
      songYoutubeUrl: fields[8] as String?,
      songSpotifyUrl: fields[9] as String?,
      songAudioUrl: fields[10] as String?,
      songThumbnailUrl: fields[3] as String?,
      songLyrics: fields[2] as String?,
      originalArtists: (fields[11] as List).cast<String>(),
      vocals: (fields[12] as List).cast<String>(),
      featuredArtists: (fields[13] as List).cast<String>(),
      audioPreedit: (fields[14] as List).cast<String>(),
      arrangement: (fields[15] as List).cast<String>(),
      artworkBy: (fields[16] as List).cast<String>(),
      videoBy: (fields[17] as List).cast<String>(),
      audioVersions: (fields[18] as List?)?.cast<AudioVersion>(),
      lyricVersions: (fields[19] as List?)?.cast<LyricVersion>(),
      localAudioPath: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.songTitle)
      ..writeByte(2)
      ..write(obj.songLyrics)
      ..writeByte(3)
      ..write(obj.songThumbnailUrl)
      ..writeByte(4)
      ..write(obj.isDraft)
      ..writeByte(5)
      ..write(obj.songLanguage)
      ..writeByte(6)
      ..write(obj.songAlbums)
      ..writeByte(7)
      ..write(obj.songReleaseDate)
      ..writeByte(8)
      ..write(obj.songYoutubeUrl)
      ..writeByte(9)
      ..write(obj.songSpotifyUrl)
      ..writeByte(10)
      ..write(obj.songAudioUrl)
      ..writeByte(11)
      ..write(obj.originalArtists)
      ..writeByte(12)
      ..write(obj.vocals)
      ..writeByte(13)
      ..write(obj.featuredArtists)
      ..writeByte(14)
      ..write(obj.audioPreedit)
      ..writeByte(15)
      ..write(obj.arrangement)
      ..writeByte(16)
      ..write(obj.artworkBy)
      ..writeByte(17)
      ..write(obj.videoBy)
      ..writeByte(18)
      ..write(obj.audioVersions)
      ..writeByte(19)
      ..write(obj.lyricVersions)
      ..writeByte(20)
      ..write(obj.localAudioPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
