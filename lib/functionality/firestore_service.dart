// The primary service for interacting with the Cloud Firestore database.
// Manages CRUD operations for songs, artists, playlists, fanart, news, and user profiles.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/functionality/artist_model.dart';
import 'package:kenoverse/functionality/playlist_model.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/fanart_model.dart';
import 'package:kenoverse/functionality/news_model.dart';

class FirestoreService {
  // Top-level collection references
  final CollectionReference songsCollection = FirebaseFirestore.instance.collection('songs');
  final CollectionReference artistsCollection = FirebaseFirestore.instance.collection('artists');
  final CollectionReference playlistsCollection = FirebaseFirestore.instance.collection('playlists');
  final CollectionReference fanartCollection = FirebaseFirestore.instance.collection('fanart');
  final CollectionReference newsCollection = FirebaseFirestore.instance.collection('news');
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  // ===========================================================================
  // USER METHODS
  // ===========================================================================

  /// Updates or sets a user's display name.
  /// If the user is new, it assigns a unique "userNumber" using a transaction
  /// to prevent race conditions during concurrent registrations.
  Future<void> updateUsername(String uid, String username) async {
    DocumentSnapshot userDoc = await usersCollection.doc(uid).get();
    Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
    
    int? userNumber = data?['userNumber'];
    
    // Assign a new sequence number if not already present
    userNumber ??= await _getNextUserNumber();

    await usersCollection.doc(uid).set({
      'username': username,
      'userNumber': userNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Atomically increments the global user counter and returns the new value.
  /// Uses a transaction to ensure no two users get the same number.
  Future<int> _getNextUserNumber() async {
    DocumentReference counterRef = FirebaseFirestore.instance.collection('counters').doc('users');
    
    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);

      // Ensure the counter document exists before attempting to read 'count'
      if (!snapshot.exists) {
        transaction.set(counterRef, {'count': 1});
        return 1;
      }

      int newCount = (snapshot.data() as Map<String, dynamic>)['count'] + 1;
      transaction.update(counterRef, {'count': newCount});
      return newCount;
    });
  }

  /// Retrieves full profile data for a specific user ID.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  /// Fetches just the username for a user, useful for displaying credits.
  Future<String?> getUsername(String uid) async {
    DocumentSnapshot doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['username'];
    }
    return null;
  }

  /// Returns a real-time stream of a user's document.
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return usersCollection.doc(uid).snapshots();
  }

  // ===========================================================================
  // SONG METHODS
  // ===========================================================================

  /// Adds a new song document to the 'songs' collection.
  Future<void> addSong(Map<String, dynamic> songData) async {
    try {
      await songsCollection.add(songData);
    } catch (e) {
      print('Error adding song: $e');
    }
  }

  /// Updates an existing song document by ID.
  Future<void> updateSong(String id, Map<String, dynamic> songData) async {
    try {
      await songsCollection.doc(id).update(songData);
    } catch (e) {
      print('Error updating song: $e');
    }
  }

  /// Permanently removes a song document.
  Future<void> deleteSong(String id) async {
    try {
      await songsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting song: $e');
    }
  }

  /// A stream of all songs, typically used for the home screen or full list.
  Stream<QuerySnapshot> get songs {
    return songsCollection.snapshots();
  }

  /// Retrieves the 10 most recently uploaded songs.
  Stream<QuerySnapshot> get recentSongs {
    return songsCollection.orderBy('timestamp', descending: true).limit(10).snapshots();
  }

  // ===========================================================================
  // ARTIST METHODS
  // ===========================================================================

  /// Retrieves an artist by name (case-insensitive slug).
  /// If the artist doesn't exist, it creates a new stub entry.
  Future<Artist> getOrCreateArtist(String name) async {
    String slug = name.toLowerCase().trim();
    DocumentSnapshot doc = await artistsCollection.doc(slug).get();
    
    if (doc.exists) {
      return Artist.fromFirestore(doc);
    } else {
      Artist newArtist = Artist(id: slug, name: name);
      await artistsCollection.doc(slug).set(newArtist.toMap());
      return newArtist;
    }
  }

  /// Updates profile information for an artist (bio, image, etc)
  Future<void> updateArtist(Artist artist) async {
    await artistsCollection.doc(artist.id).update(artist.toMap());
  }

  /// Real-time stream for an artist's profile page.
  Stream<DocumentSnapshot> getArtistStream(String artistId) {
    return artistsCollection.doc(artistId).snapshots();
  }

  /// Finds all songs where the given artist name is listed as a contributor.
  /// Relies on the 'allContributors' array field in song documents.
  Stream<QuerySnapshot> getSongsByArtist(String artistName) {
    String slug = artistName.toLowerCase().trim();
    return songsCollection.where('allContributors', arrayContains: slug).snapshots();
  }

  /// Implements a basic client-side search by fetching song metadata.
  /// Iterates through title, albums, lyrics, and contributors for partial matches.
  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    String q = query.toLowerCase().trim();
    
    // Fetch all songs for local filtering (most reliable for partial matches across all fields)
    QuerySnapshot snapshot = await songsCollection.get();

    return snapshot.docs.map((doc) {
      return Song.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).where((song) {
      final titleMatch = song.songTitle.toLowerCase().contains(q);
      final albumMatch = song.songAlbums.any((a) => a.toLowerCase().contains(q));
      final lyricMatch = (song.songLyrics ?? '').toLowerCase().contains(q);
      
      final contributorMatch = [
        ...song.originalArtists,
        ...song.vocals,
        ...song.featuredArtists,
        ...song.audioPreedit,
        ...song.arrangement,
        ...song.artworkBy,
        ...song.videoBy,
      ].any((c) => c.toLowerCase().contains(q));

      return titleMatch || albumMatch || lyricMatch || contributorMatch;
    }).toList();
  }

  // ===========================================================================
  // PLAYLIST METHODS
  // ===========================================================================

  /// Creates a new user-owned playlist.
  Future<void> createPlaylist(Playlist playlist) async {
    await playlistsCollection.add(playlist.toMap());
  }

  /// Updates playlist metadata (name, description).
  Future<void> updatePlaylist(String id, Map<String, dynamic> data) async {
    await playlistsCollection.doc(id).update(data);
  }

  /// Deletes a playlist.
  Future<void> deletePlaylist(String id) async {
    await playlistsCollection.doc(id).delete();
  }

  /// Streams all playlists belonging to a specific user.
  Stream<QuerySnapshot> getUserPlaylists(String userId) {
    return playlistsCollection.where('userId', isEqualTo: userId).snapshots();
  }

  /// Appends a song ID to a playlist's 'songIds' array using FieldValue.arrayUnion.
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await playlistsCollection.doc(playlistId).update({
      'songIds': FieldValue.arrayUnion([songId])
    });
  }

  /// Removes a song ID from a playlist using FieldValue.arrayRemove.
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await playlistsCollection.doc(playlistId).update({
      'songIds': FieldValue.arrayRemove([songId])
    });
  }

  /// Resolves a list of song IDs into a list of Song model objects.
  Future<List<Song>> getPlaylistSongs(List<String> songIds) async {
    if (songIds.isEmpty) return [];
    
    List<Song> songs = [];
    for (var id in songIds) {
      DocumentSnapshot doc = await songsCollection.doc(id).get();
      if (doc.exists) {
        songs.add(Song.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
    }
    return songs;
  }

  // ===========================================================================
  // LIKED SONGS & HISTORY
  // ===========================================================================

  /// Toggles a song's 'liked' status for a user.
  /// Stores likes in a user-specific sub-collection for easier querying.
  Future<void> toggleLike(String userId, String songId) async {
    DocumentReference likeRef = usersCollection.doc(userId).collection('liked_songs').doc(songId);

    DocumentSnapshot doc = await likeRef.get();
    if (doc.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        'songId': songId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Returns a stream indicating if a specific song is liked by a user.
  Stream<bool> isLiked(String userId, String songId) {
    return usersCollection.doc(userId).collection('liked_songs').doc(songId).snapshots().map((doc) => doc.exists);
  }

  /// Streams the user's liked songs, ordered by when they were liked.
  Stream<QuerySnapshot> getLikedSongsStream(String userId) {
    return usersCollection.doc(userId).collection('liked_songs').orderBy('timestamp', descending: true).snapshots();
  }

  /// Adds a song to the user's recently viewed history.
  /// If already in history, it updates the timestamp to move it to the top.
  Future<void> addToHistory(String userId, String songId) async {
    final historyRef = usersCollection.doc(userId).collection('history').doc(songId);
    
    await historyRef.set({
      'songId': songId,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Streams the user's recent history, limited to the last 10 entries.
  Stream<QuerySnapshot> getHistoryStream(String userId) {
    return usersCollection.doc(userId).collection('history').orderBy('timestamp', descending: true).limit(10).snapshots();
  }

  // ===========================================================================
  // OTHER MEDIA
  // ===========================================================================

  /// Submits new community fanart.
  Future<void> addFanart(Fanart fanart) async {
    await fanartCollection.add(fanart.toMap());
  }

  /// Streams fanart in chronological order.
  Stream<QuerySnapshot> get fanartStream {
    return fanartCollection.orderBy('timestamp', descending: true).snapshots();
  }

  /// Submits a new news article (typically for admin use).
  Future<void> addNews(NewsArticle article) async {
    await newsCollection.add(article.toMap());
  }

  /// Streams official news updates.
  Stream<QuerySnapshot> get newsStream {
    return newsCollection.orderBy('timestamp', descending: true).snapshots();
  }
}
