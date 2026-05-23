import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kenoverse/functionality/lyrics.dart';

/// DownloadService is responsible for managing local audio file storage.
/// It uses the Dio library for robust HTTP downloads and progress tracking.
class DownloadService {
  final Dio _dio = Dio();

  /// Starts downloading the primary mp3 for a given [song].
  /// On success, it updates the [song.localAudioPath] and persists the change to Hive.
  Future<void> downloadSongAudio(Song song) async {
    // We can't download what doesn't have a URL.
    if (song.songAudioUrl == null || song.songAudioUrl!.isEmpty) {
      throw Exception('This song does not have a downloadable audio URL.');
    }

    try {
      // Find a safe place to store files (Documents directory on mobile).
      final appDocDir = await getApplicationDocumentsDirectory();
      
      // Use the Firestore ID to create a unique filename.
      final fileName = '${song.id}_audio.mp3';
      final savePath = '${appDocDir.path}/$fileName';

      debugPrint('DownloadService: Starting download for ${song.songTitle}');

      // Perform the actual download.
      await _dio.download(
        song.songAudioUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Optional: You could expose this percentage via a Stream to show a progress bar.
            debugPrint('Download Progress (${song.songTitle}): ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      // Link the local file path to the song object.
      song.localAudioPath = savePath;
      
      // Persist the updated path in Hive immediately.
      await song.save();

      debugPrint('DownloadService: Successfully saved audio to $savePath');
    } catch (e) {
      debugPrint('DownloadService Error during download: $e');
      rethrow;
    }
  }

  /// Checks if the audio file exists on the device's storage.
  bool isDownloaded(Song song) {
    if (song.localAudioPath == null) return false;
    return File(song.localAudioPath!).existsSync();
  }

  /// Removes the downloaded file from storage and clears the metadata.
  Future<void> deleteDownloadedAudio(Song song) async {
    if (song.localAudioPath != null) {
      final file = File(song.localAudioPath!);
      if (file.existsSync()) {
        await file.delete();
        debugPrint('DownloadService: Deleted local file for ${song.songTitle}');
      }
      song.localAudioPath = null;
      await song.save();
    }
  }
}
