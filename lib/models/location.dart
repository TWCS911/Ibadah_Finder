import 'review.dart';

class Location {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final List<Review> reviews;

  Location({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
  });

  factory Location.fromMap(Map<String, dynamic> data, String id) {
    return Location(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviews: (data['reviews'] as List<dynamic>?)
              ?.map((e) => Review.fromMap(e))
              .toList() ??
          [],
    );
  }
}
