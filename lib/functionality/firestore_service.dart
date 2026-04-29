import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference songsCollection = FirebaseFirestore.instance.collection('songs');

  Future<void> addSong(Map<String, dynamic> songData) async {
    try {
      await songsCollection.add(songData);
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
}
