import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'add_review_screen.dart';

class ReviewScreen extends StatefulWidget {
  final String locationId;

  const ReviewScreen({super.key, required this.locationId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int? selectedRatingFilter; // null = all, 1..5 = filter by rating

  String formatReviewDate(String rawDate) {
    try {
      DateTime dateTime = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return rawDate;
    }
  }

  Future<String?> _fetchUserProfilePicture(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return data['profilePictureBase64'];  // Mengambil profilePictureBase64 berdasarkan userId
      }
    } catch (e) {
      print('Error fetching user profile picture: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Reviews', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Filter by rating: ",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                DropdownButton<int?>(
                  value: selectedRatingFilter,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All'),
                    ),
                    for (int i = 1; i <= 5; i++)
                      DropdownMenuItem<int>(
                        value: i,
                        child: Row(
                          children: [
                            Text('$i'),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                          ],
                        ),
                      )
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRatingFilter = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('locations').doc(widget.locationId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading reviews: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final reviewsAll = data['reviews'] as List<dynamic>? ?? [];

                // Filter reviews sesuai filter yang dipilih
                final filteredReviews = selectedRatingFilter == null
                    ? reviewsAll
                    : reviewsAll.where((r) {
                        if (r is Map<String, dynamic>) {
                          final rating = (r['rating'] ?? 0.0).toDouble();
                          return rating.toInt() == selectedRatingFilter;
                        }
                        return false;
                      }).toList();

                if (filteredReviews.isEmpty) {
                  return Center(
                    child: Text('No reviews matching the filter', style: GoogleFonts.inter(fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    final review = filteredReviews[index] as Map<String, dynamic>;

                    final userName = review['userName'] ?? 'Anonymous';
                    final userId = review['userId'] ?? '';  // Menambahkan userId dari review
                    final postDateRaw = review['postDate'] ?? '';
                    final postDate = formatReviewDate(postDateRaw);
                    final reviewRating = (review['rating'] ?? 0.0).toDouble();
                    final comment = review['comment'] ?? '';
                    final photos = review['photos'] as List<dynamic>? ?? [];

                    // Mengambil profilePictureBase64 berdasarkan userId
                    return FutureBuilder<String?>(
                      future: _fetchUserProfilePicture(userId),
                      builder: (context, profileSnapshot) {
                        if (profileSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final userProfileBase64 = profileSnapshot.data ?? '';

                        Widget profileImage;
                        if (userProfileBase64.isNotEmpty) {
                          try {
                            Uint8List profileBytes = base64Decode(userProfileBase64);
                            profileImage = CircleAvatar(
                              radius: 28,
                              backgroundImage: MemoryImage(profileBytes),
                            );
                          } catch (e) {
                            profileImage = CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade300,
                              child: const Icon(Icons.person, color: Colors.grey),
                            );
                          }
                        } else {
                          profileImage = CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(Icons.person, color: Colors.grey),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  profileImage,
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(userName,
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700, fontSize: 18)),
                                        const SizedBox(height: 4),
                                        Text(postDate,
                                            style: GoogleFonts.inter(
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(reviewRating.toStringAsFixed(1),
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700, fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(comment,
                                    style: GoogleFonts.inter(
                                        fontSize: 14, height: 1.4)),
                              ],
                              if (photos.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: photos.length,
                                    itemBuilder: (context, photoIndex) {
                                      final photoBase64 = photos[photoIndex];
                                      Widget photoWidget;
                                      if (photoBase64.isNotEmpty) {
                                        try {
                                          Uint8List photoBytes = base64Decode(photoBase64);
                                          photoWidget = ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.memory(
                                              photoBytes,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        } catch (e) {
                                          photoWidget = Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          );
                                        }
                                      } else {
                                        photoWidget = Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: photoWidget,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5A55CA),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddReviewScreen(locationId: widget.locationId)),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
