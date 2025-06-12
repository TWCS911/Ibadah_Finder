import 'dart:convert';
import 'dart:typed_data';
import 'package:fasum/screens/cover_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'dart:math'; // Untuk random selection
import 'package:geolocator/geolocator.dart'; // Import Geolocator package

import 'add_location_screen.dart';
import 'detail_screen.dart';
import 'sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // pastikan ditambahkan di pubspec.yaml

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';
  String? selectedCategory;
  double? userLatitude;
  double? userLongitude;
  String selectedFilter = 'All'; // Filter jarak, All = tidak ada filter jarak

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Mengambil lokasi pengguna saat ini
  }

  // Fungsi untuk mengubah teks menjadi capitalized (setiap kata dimulai dengan huruf besar)
  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      return word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '';
    }).join(' ');
  }

  // Menghitung rata-rata rating dari review
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

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => CoverScreen()),
    );
  }

  // Mengambil username berdasarkan UID
  Future<String> getUsernameByUid(String uid) async {
    if (uid.isEmpty) return 'Unknown';
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return 'Unknown';
    final data = doc.data();
    if (data == null) return 'Unknown';
    return data['username'] ?? 'Unknown';
  }

  // Mengambil foto profil berdasarkan userId
  Future<String> getUserProfilePicture(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['profilePictureBase64'] ?? ''; // Return the base64 string of the profile picture
      }
    } catch (e) {
      print("Error getting user profile picture: $e");
    }
    return '';
  }

  // Format tanggal review
  String formatReviewDate(String rawDate) {
    try {
      DateTime dateTime = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return rawDate;
    }
  }

  // Mendapatkan lokasi pengguna saat ini
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Mengecek status layanan GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Jika layanan GPS tidak aktif
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        // Jika izin GPS ditolak
        return;
      }
    }

    // Mendapatkan posisi pengguna
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      userLatitude = position.latitude;
      userLongitude = position.longitude;
    });
  }

  // Menghitung jarak antara dua titik menggunakan rumus Haversine
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // Radius bumi dalam kilometer
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = radius * c; // Hasil jarak dalam kilometer

    return distance;
  }

  @override
  Widget build(BuildContext context) {
    final locationsStream = FirebaseFirestore.instance
        .collection('locations')
        .orderBy('name')
        .startAt([searchQuery.toLowerCase()])
        .endAt([searchQuery.toLowerCase() + '\uf8ff'])
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Home', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () => signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search places of worship...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
            ),
          ),
          // Filter Kategori
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              hint: const Text("Select Category"),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue;
                });
              },
              items: <String>['All', 'Masjid', 'Gereja', 'Kelenteng', 'Vihara']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          // Filter Jarak
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              hint: const Text("Filter by Distance"),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  selectedFilter = newValue!;
                });
              },
              items: <String>['All', 'Within 5 km', 'Within 10 km', 'Within 20 km']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: locationsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading locations: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No locations found'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = capitalizeWords(data['name'] ?? '');  // Capitalize name
                    final description = data['description'] ?? '';
                    final reviews = data['reviews'] as List<dynamic>? ?? [];
                    final rating = calculateAverageRating(reviews);
                    final uploadedByUid = data['uploadedByUid'] ?? '';
                    final Timestamp? createdAtTimestamp = data['createdAt'];
                    final createdAt = createdAtTimestamp != null ? createdAtTimestamp.toDate() : null;
                    final createdAtStr = createdAt != null
                        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                        : 'Unknown date';

                    final base64String = data['imageBase64'] ?? '';

                    // Filter berdasarkan kategori tempat ibadah
                    if (selectedCategory != null && selectedCategory != 'All' && !name.toLowerCase().contains(selectedCategory!.toLowerCase())) {
                      return SizedBox.shrink(); // Lokasi tidak ditampilkan
                    }

                    // Menghitung jarak antara pengguna dan lokasi
                    double distance = 0.0;
                    if (userLatitude != null && userLongitude != null) {
                      distance = calculateDistance(
                        userLatitude!,
                        userLongitude!,
                        data['latitude'] ?? 0.0,
                        data['longitude'] ?? 0.0,
                      );
                    }

                    // Filter lokasi dalam jarak tertentu berdasarkan pilihan filter
                    if (selectedFilter == 'Within 5 km' && distance > 5.0) {
                      return SizedBox.shrink(); // Lokasi tidak ditampilkan
                    } else if (selectedFilter == 'Within 10 km' && distance > 10.0) {
                      return SizedBox.shrink(); // Lokasi tidak ditampilkan
                    } else if (selectedFilter == 'Within 20 km' && distance > 20.0) {
                      return SizedBox.shrink(); // Lokasi tidak ditampilkan
                    }

                    Widget mainImageWidget;
                    if (base64String.isNotEmpty) {
                      try {
                        Uint8List bytes = base64Decode(base64String);
                        img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
                        if (image != null) {
                          img.Image resized = img.copyResize(image, width: 300);
                          bytes = Uint8List.fromList(img.encodeJpg(resized)); // Convert back to bytes
                        }
                        mainImageWidget = ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        );
                      }
                    } else {
                      mainImageWidget = Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailScreen(locationId: docs[index].id)),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            mainImageWidget,
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
                                  const SizedBox(height: 8),
                                  Text(description, style: GoogleFonts.inter(fontSize: 14)),
                                  const SizedBox(height: 8),
                                  FutureBuilder<String>(
                                    future: getUsernameByUid(uploadedByUid),
                                    builder: (context, snapshot) {
                                      String username = 'Loading...';
                                      if (snapshot.connectionState == ConnectionState.done) {
                                        username = snapshot.data ?? 'Unknown';
                                      }
                                      return Text(
                                        'Uploaded by $username on $createdAtStr',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 22),
                                      const SizedBox(width: 6),
                                      Text(rating.toStringAsFixed(1),
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  reviews.isEmpty
                                      ? const Center(child: Text('No reviews yet'))
                                      : Builder(
                                          builder: (context) {
                                            // Mengambil review secara acak
                                            final randomReview = reviews[Random().nextInt(reviews.length)];

                                            final userName = randomReview['userName'] ?? 'Anonymous';
                                            final userId = randomReview['userId'] ?? ''; // Use the userId from the review
                                            final reviewComment = randomReview['comment'] ?? ''; // Get review comment

                                            // Use FutureBuilder to fetch the profile picture asynchronously
                                            return FutureBuilder<String>(
                                              future: getUserProfilePicture(userId),
                                              builder: (context, userProfileSnapshot) {
                                                Widget profileImage;
                                                if (userProfileSnapshot.connectionState == ConnectionState.done) {
                                                  String userProfileBase64 = userProfileSnapshot.data ?? '';
                                                  if (userProfileBase64.isNotEmpty) {
                                                    try {
                                                      Uint8List profileBytes = base64Decode(userProfileBase64);
                                                      profileImage = CircleAvatar(
                                                        radius: 24,
                                                        backgroundImage: MemoryImage(profileBytes),
                                                      );
                                                    } catch (e) {
                                                      profileImage = CircleAvatar(
                                                        radius: 24,
                                                        backgroundColor: Colors.grey.shade300,
                                                        child: const Icon(Icons.person, color: Colors.grey),
                                                      );
                                                    }
                                                  } else {
                                                    profileImage = CircleAvatar(
                                                      radius: 24,
                                                      backgroundColor: Colors.grey.shade300,
                                                      child: const Icon(Icons.person, color: Colors.grey),
                                                    );
                                                  }
                                                } else {
                                                  profileImage = CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor: Colors.grey.shade300,
                                                    child: const Icon(Icons.person, color: Colors.grey),
                                                  );
                                                }

                                                final reviewRating = (randomReview['rating'] ?? 0.0).toDouble();
                                                final photos = randomReview['photos'] as List<dynamic>? ?? [];

                                                return Container(
                                                  width: double.infinity,
                                                  margin: const EdgeInsets.only(top: 8),
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          profileImage,
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(userName,
                                                                    style: GoogleFonts.inter(
                                                                        fontWeight: FontWeight.w700, fontSize: 16)),
                                                                Text(formatReviewDate(randomReview['postDate'] ?? ''),
                                                                    style: GoogleFonts.inter(
                                                                        fontSize: 12, color: Colors.grey[600])),
                                                              ],
                                                            ),
                                                          ),
                                                          // Menampilkan Rating
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.star, color: Colors.amber, size: 18),
                                                              Text(reviewRating.toStringAsFixed(1),
                                                                  style: GoogleFonts.inter(
                                                                      fontWeight: FontWeight.w700, fontSize: 14)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 12),
                                                      // Menampilkan teks review (comment)
                                                      Text(reviewComment, style: GoogleFonts.inter(fontSize: 14)),
                                                      const SizedBox(height: 12),
                                                      // Menampilkan foto review jika ada
                                                      if (photos.isNotEmpty)
                                                        SizedBox(
                                                          height: 60,
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
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    child: Image.memory(
                                                                      photoBytes,
                                                                      width: 60,
                                                                      height: 60,
                                                                      fit: BoxFit.cover,
                                                                    ),
                                                                  );
                                                                } catch (e) {
                                                                  photoWidget = Container(
                                                                    width: 60,
                                                                    height: 60,
                                                                    color: Colors.grey.shade300,
                                                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                                                  );
                                                                }
                                                              } else {
                                                                photoWidget = Container(
                                                                  width: 60,
                                                                  height: 60,
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
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5A55CA),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddLocationScreen()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
