import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> songIds;
  final String? thumbnailUrl;

  Playlist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.songIds = const [],
    this.thumbnailUrl,
  });

  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Playlist(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Untitled Playlist',
      description: data['description'],
      songIds: List<String>.from(data['songIds'] ?? []),
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'songIds': songIds,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
