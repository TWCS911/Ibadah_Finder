import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

// Tambahkan import flutter_image_compress
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddReviewScreen extends StatefulWidget {
  final String locationId;

  const AddReviewScreen({super.key, required this.locationId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0;
  List<String> _photoBase64List = [];

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Fungsi compress file gambar
  Future<Uint8List?> _compressFile(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 60, // kualitas kompresi, bisa disesuaikan
      minWidth: 800, // resize lebar maksimal
      minHeight: 800, // resize tinggi maksimal
      format: CompressFormat.jpeg,
    );
    return result;
  }

  Future<void> _pickImage() async {
    if (_photoBase64List.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }

    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      // Kompres gambar dulu
      Uint8List? compressedBytes = await _compressFile(File(pickedImage.path));
      if (compressedBytes == null) {
        // Jika kompres gagal fallback pakai bytes asli
        compressedBytes = await pickedImage.readAsBytes();
      }
      final base64Str = base64Encode(compressedBytes);
      setState(() {
        _photoBase64List.add(base64Str);
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['username'] ?? 'Anonymous';

      final reviewData = {
        'userId': user.uid,
        'userName': username,
        'userProfileBase64': '', // optional
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'photos': _photoBase64List,
        'postDate': DateTime.now().toIso8601String(),
      };

      final locationRef = FirebaseFirestore.instance.collection('locations').doc(widget.locationId);

      await locationRef.update({
        'reviews': FieldValue.arrayUnion([reviewData]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            _rating >= starIndex ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 36,
          ),
          onPressed: () {
            setState(() {
              _rating = starIndex.toDouble();
            });
          },
        );
      }),
    );
  }

  Widget _buildPhotoPreview() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _photoBase64List.length + 1,
        itemBuilder: (context, index) {
          if (index == _photoBase64List.length) {
            // Add photo button
            return GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_a_photo, size: 36, color: Colors.grey),
              ),
            );
          }

          final base64Str = _photoBase64List[index];
          Uint8List bytes = base64Decode(base64Str);

          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: MemoryImage(bytes),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _photoBase64List.removeAt(index);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Review', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Rate this location', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 12),
              _buildRatingStars(),

              const SizedBox(height: 24),

              TextFormField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Write your review',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your review';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              Text('Upload photos (optional)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),

              _buildPhotoPreview(),

              const SizedBox(height: 40),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF5A55CA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Submit Review', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
