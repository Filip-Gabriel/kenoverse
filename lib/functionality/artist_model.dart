// Data model representing an artist or creator profile.
// Stores biography, social media links, and ownership information.
import 'package:cloud_firestore/cloud_firestore.dart';

class Artist {
  final String id; // This will be the artist name (lowercase/slug) or document ID
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final Map<String, String>? socialMedia; // e.g., {'twitter': '...', 'spotify': '...'}
  final String? claimedBy; // User ID of the user who claimed this profile

  Artist({
    required this.id,
    required this.name,
    this.bio,
    this.profileImageUrl,
    this.socialMedia,
    this.claimedBy,
  });

  factory Artist.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Artist(
      id: doc.id,
      name: data['name'] ?? 'Unknown Artist',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      socialMedia: data['socialMedia'] != null ? Map<String, String>.from(data['socialMedia']) : null,
      claimedBy: data['claimedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'socialMedia': socialMedia,
      'claimedBy': claimedBy,
    };
  }
}
