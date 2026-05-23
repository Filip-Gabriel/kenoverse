import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/lyrics.dart';

/// SyncService maintains a high-performance local mirror of song metadata.
/// It uses Firestore's real-time snapshots to ensure the local database only
/// updates when remote data actually changes.
class SyncService {
  /// The name of the Hive box used to store [Song] objects.
  static const String songBoxName = 'songs_box';
  
  final FirestoreService _firestore = FirestoreService();
  
  /// Subscription to the remote Firestore collection.
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  /// Initializes the local database and begins listening for remote changes.
  Future<void> init() async {
    // Initialize Hive with Flutter-specific paths
    await Hive.initFlutter();
    
    // Register the auto-generated adapters for our custom models.
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SongAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AudioVersionAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(LyricVersionAdapter());

    // Open the local storage box.
    await Hive.openBox<Song>(songBoxName);

    // Start the reactive sync process.
    _startSyncListener();
  }

  /// Sets up a real-time listener on the Firestore 'songs' collection.
  /// This listener updates the local Hive box incrementally.
  void _startSyncListener() {
    _firestoreSubscription = _firestore.songsCollection.snapshots().listen((snapshot) async {
      final box = Hive.box<Song>(songBoxName);

      debugPrint('SyncService: Received ${snapshot.docChanges.length} change(s) from Firebase.');

      for (var change in snapshot.docChanges) {
        final doc = change.doc;
        final songId = doc.id;

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            // Convert Firestore data into our local model.
            final remoteSong = Song.fromFirestore(doc.data() as Map<String, dynamic>, songId);
            
            // Preserve the device-specific localAudioPath if the song already exists in Hive.
            final existingSong = box.get(songId);
            if (existingSong != null) {
              remoteSong.localAudioPath = existingSong.localAudioPath;
            }

            // Save or update the song in the local database.
            await box.put(songId, remoteSong);
            debugPrint('SyncService: ${change.type == DocumentChangeType.added ? 'Added' : 'Updated'} song: ${remoteSong.songTitle}');
            break;

          case DocumentChangeType.removed:
            // If a song is deleted from Firestore, remove it from the device as well.
            await box.delete(songId);
            debugPrint('SyncService: Removed song with ID: $songId');
            break;
        }
      }
    }, onError: (error) {
      debugPrint('SyncService Listener Error: $error');
    });
  }

  /// Synchronous getter for all songs currently mirrored on the device.
  List<Song> getLocalSongs() {
    final box = Hive.box<Song>(songBoxName);
    return box.values.toList();
  }

  /// Reactive stream that emits the full list of local songs.
  /// It yields the current cached data immediately upon subscription,
  /// then continues to emit the updated list whenever the database changes.
  Stream<List<Song>> getLocalSongsStream() async* {
    final box = Hive.box<Song>(songBoxName);
    
    // Yield the current contents of the box immediately.
    yield box.values.toList();

    // Listen for future changes and yield the updated list.
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }

  /// Stops listening to Firebase updates.
  void dispose() {
    _firestoreSubscription?.cancel();
  }
}
