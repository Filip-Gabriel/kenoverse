// Data model representing a news article in the KenoVerse app.
// Handles Firestore document conversion and serialization.
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final DateTime timestamp;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.timestamp,
  });

  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
