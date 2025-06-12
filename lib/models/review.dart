import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String username;
  final String comment;
  final double rating;
  final DateTime date;

  Review({
    required this.username,
    required this.comment,
    required this.rating,
    required this.date,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      username: data['username'] ?? '',
      comment: data['comment'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
