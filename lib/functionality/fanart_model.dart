// Data model for community-uploaded fanart and illustrations.
// Links artwork to specific songs and uploaders.
import 'package:cloud_firestore/cloud_firestore.dart';

class Fanart {
  final String id;
  final String imageUrl;
  final String uploaderId;
  final String? songId; // Optional: Link to a specific song
  final String? artistName; // Name of the creator/user
  final DateTime timestamp;

  Fanart({
    required this.id,
    required this.imageUrl,
    required this.uploaderId,
    this.songId,
    this.artistName,
    required this.timestamp,
  });

  factory Fanart.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Fanart(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      uploaderId: data['uploaderId'] ?? '',
      songId: data['songId'],
      artistName: data['artistName'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'uploaderId': uploaderId,
      'songId': songId,
      'artistName': artistName,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
