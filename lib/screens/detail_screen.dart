import 'dart:convert';
import 'dart:typed_data';

import 'package:fasum/screens/favorites_screen.dart';
import 'package:fasum/screens/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class DetailScreen extends StatefulWidget {
  final String locationId;

  const DetailScreen({super.key, required this.locationId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;
  double? _latitude;
  double? _longitude;

  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Fungsi untuk mengubah teks menjadi capitalized (setiap kata dimulai dengan huruf besar)
  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      return word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '';
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    if (_currentUserId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .doc(widget.locationId)
          .get();

      setState(() {
        isFavorite = doc.exists;
      });
    } catch (e) {
      // ignore errors here or log if needed
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use favorites')),
      );
      return;
    }

    final favDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('favorites')
        .doc(widget.locationId);

    try {
      if (isFavorite) {
        // Hapus dari favorites
        await favDocRef.delete();
        setState(() {
          isFavorite = false;
        });
      } else {
        // Ambil data lokasi yang sedang ditampilkan (minimal name, imageBase64, description, latitude, longitude)
        final locationDoc = await FirebaseFirestore.instance
            .collection('locations')
            .doc(widget.locationId)
            .get();

        if (!locationDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location data not found')),
          );
          return;
        }

        final locationData = locationDoc.data()!;
        await favDocRef.set({
          'locationId': widget.locationId,
          'name': locationData['name'] ?? '',
          'description': locationData['description'] ?? '',
          'imageBase64': locationData['imageBase64'] ?? '',
          'latitude': locationData['latitude'] ?? 0.0,
          'longitude': locationData['longitude'] ?? 0.0,
          'addedAt': Timestamp.now(),
        });
        setState(() {
          isFavorite = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorites: $e')),
      );
    }
  }

  double calculateAverageRating(List<dynamic> reviews) {
    if (reviews.isEmpty) return 0.0;

    double total = 0;
    int count = 0;

    for (var review in reviews) {
      if (review is Map<String, dynamic> && review.containsKey('rating')) {
        final r = review['rating'];
        if (r != null) {
          total += (r as num).toDouble();
          count++;
        }
      }
    }
    if (count == 0) return 0.0;
    return total / count;
  }

  String formatReviewDate(String rawDate) {
    try {
      DateTime dateTime = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> _launchMaps(double latitude, double longitude, BuildContext context) async {
    final Uri googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
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
        title: Text('Location Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 1,
        actions: [],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('locations').doc(widget.locationId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading details: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final name = capitalizeWords(data['name'] ?? ''); // Capitalize location name
          final description = data['description'] ?? '';
          final reviewsAll = data['reviews'] as List<dynamic>? ?? [];
          final rating = calculateAverageRating(reviewsAll);

          final base64String = data['imageBase64'] ?? '';
          Widget mainImageWidget;
          if (base64String.isNotEmpty) {
            try {
              Uint8List bytes = base64Decode(base64String);
              mainImageWidget = ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  bytes,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            } catch (e) {
              mainImageWidget = Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
              );
            }
          } else {
            mainImageWidget = Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            );
          }

          _latitude = (data['latitude'] ?? 0.0).toDouble();
          _longitude = (data['longitude'] ?? 0.0).toDouble();

          List<dynamic> displayedReviews = [];
          if (reviewsAll.isNotEmpty) {
            displayedReviews = List.from(reviewsAll);
            displayedReviews.shuffle(Random());
            displayedReviews = displayedReviews.take(3).toList();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView(
              children: [
                const SizedBox(height: 12),
                mainImageWidget,
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 28)),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? const Color(0xFF5A55CA) : Colors.grey,
                        size: 32,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(locationId: widget.locationId),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Reviews',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (displayedReviews.isEmpty)
                  Center(child: Text('No reviews yet', style: GoogleFonts.inter(fontSize: 16))),
                if (displayedReviews.isNotEmpty)
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: displayedReviews.length,
                    itemBuilder: (context, index) {
                      final review = displayedReviews[index] as Map<String, dynamic>;

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

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewScreen(locationId: widget.locationId),
                                ),
                              );
                            },
                            child: Container(
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
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () {
            if (_latitude != null && _longitude != null) {
              _launchMaps(_latitude!, _longitude!, context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location coordinates not available')),
              );
            }
          },
          icon: const Icon(Icons.directions, color: Colors.white),
          label: Text('Get Directions',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF5A55CA),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
