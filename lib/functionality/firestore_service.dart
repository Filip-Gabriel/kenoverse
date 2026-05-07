import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenoverse/functionality/artist_model.dart';
import 'package:kenoverse/functionality/playlist_model.dart';
import 'package:kenoverse/functionality/lyrics.dart';
import 'package:kenoverse/functionality/fanart_model.dart';
import 'package:kenoverse/functionality/news_model.dart';

class FirestoreService {
  final CollectionReference songsCollection = FirebaseFirestore.instance.collection('songs');
  final CollectionReference artistsCollection = FirebaseFirestore.instance.collection('artists');
  final CollectionReference playlistsCollection = FirebaseFirestore.instance.collection('playlists');
  final CollectionReference fanartCollection = FirebaseFirestore.instance.collection('fanart');
  final CollectionReference newsCollection = FirebaseFirestore.instance.collection('news');
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  // User methods
  Future<void> updateUsername(String uid, String username) async {
    // Check if user already has a number
    DocumentSnapshot userDoc = await usersCollection.doc(uid).get();
    Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
    
    int? userNumber = data?['userNumber'];
    
    userNumber ??= await _getNextUserNumber();

    await usersCollection.doc(uid).set({
      'username': username,
      'userNumber': userNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> _getNextUserNumber() async {
    DocumentReference counterRef = FirebaseFirestore.instance.collection('counters').doc('users');
    
    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);

      int newCount = (snapshot.data() as Map<String, dynamic>)['count'] + 1;
      transaction.update(counterRef, {'count': newCount});
      return newCount;
    });
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<String?> getUsername(String uid) async {
    DocumentSnapshot doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['username'];
    }
    return null;
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return usersCollection.doc(uid).snapshots();
  }

  // Song methods...
  Future<void> addSong(Map<String, dynamic> songData) async {
    try {
      await songsCollection.add(songData);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> updateSong(String id, Map<String, dynamic> songData) async {
    try {
      await songsCollection.doc(id).update(songData);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deleteSong(String id) async {
    try {
      await songsCollection.doc(id).delete();
    } catch (e) {
      print(e.toString());
    }
  }

  Stream<QuerySnapshot> get songs {
    return songsCollection.snapshots();
  }

  Stream<QuerySnapshot> get recentSongs {
    return songsCollection.orderBy('timestamp', descending: true).limit(10).snapshots();
  }

  // Artist methods
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

  Future<void> updateArtist(Artist artist) async {
    await artistsCollection.doc(artist.id).update(artist.toMap());
  }

  Stream<DocumentSnapshot> getArtistStream(String artistId) {
    return artistsCollection.doc(artistId).snapshots();
  }

  Stream<QuerySnapshot> getSongsByArtist(String artistName) {
    String slug = artistName.toLowerCase().trim();
    return songsCollection.where('allContributors', arrayContains: slug).snapshots();
  }

  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    String q = query.toLowerCase().trim();
    
    // Fetch all songs for local filtering (most reliable for partial matches across all fields)
    QuerySnapshot snapshot = await songsCollection.get();

    return snapshot.docs.map((doc) {
      return Song.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).where((song) {
      // Search in everything: title, albums, lyrics, contributors
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

  // Playlist methods
  Future<void> createPlaylist(Playlist playlist) async {
    await playlistsCollection.add(playlist.toMap());
  }

  Future<void> updatePlaylist(String id, Map<String, dynamic> data) async {
    await playlistsCollection.doc(id).update(data);
  }

  Future<void> deletePlaylist(String id) async {
    await playlistsCollection.doc(id).delete();
  }

  Stream<QuerySnapshot> getUserPlaylists(String userId) {
    return playlistsCollection.where('userId', isEqualTo: userId).snapshots();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await playlistsCollection.doc(playlistId).update({
      'songIds': FieldValue.arrayUnion([songId])
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await playlistsCollection.doc(playlistId).update({
      'songIds': FieldValue.arrayRemove([songId])
    });
  }

  Future<List<Song>> getPlaylistSongs(List<String> songIds) async {
    if (songIds.isEmpty) return [];
    
    // Firestore 'in' query has a limit of 10-30 depending on version, 
    // usually 10. For now let's do a simple implementation.
    // If list is large we should chunk it.
    List<Song> songs = [];
    for (var id in songIds) {
      DocumentSnapshot doc = await songsCollection.doc(id).get();
      if (doc.exists) {
        songs.add(Song.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
    }
    return songs;
  }

  // Liked Songs methods
  Future<void> toggleLike(String userId, String songId) async {
    DocumentReference likeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('liked_songs')
        .doc(songId);

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

  Stream<bool> isLiked(String userId, String songId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('liked_songs')
        .doc(songId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<QuerySnapshot> getLikedSongsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('liked_songs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Fanart methods
  Future<void> addFanart(Fanart fanart) async {
    await fanartCollection.add(fanart.toMap());
  }

  Stream<QuerySnapshot> get fanartStream {
    return fanartCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // News methods
  Future<void> addNews(NewsArticle article) async {
    await newsCollection.add(article.toMap());
  }

  Stream<QuerySnapshot> get newsStream {
    return newsCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // History methods
  Future<void> addToHistory(String userId, String songId) async {
    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history');
    
    // Check if it already exists to update the timestamp
    final doc = await historyRef.doc(songId).get();
    if (doc.exists) {
      await historyRef.doc(songId).update({
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await historyRef.doc(songId).set({
        'songId': songId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot> getHistoryStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }
}
