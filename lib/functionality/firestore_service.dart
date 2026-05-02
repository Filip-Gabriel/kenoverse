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
    await usersCollection.doc(uid).set({
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
}
