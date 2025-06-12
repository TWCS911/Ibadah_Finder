import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _emailController = TextEditingController();

  Uint8List? _profilePictureBytes;
  File? _pickedImageFile;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      _nameController.text = data['username'] ?? '';
      _descController.text = data['profileDescription'] ?? '';
      _emailController.text = _currentUser!.email ?? '';

      final base64Image = data['profilePictureBase64'] ?? '';
      if (base64Image.isNotEmpty) {
        try {
          _profilePictureBytes = base64Decode(base64Image);
        } catch (_) {
          _profilePictureBytes = null;
        }
      }

      setState(() {});
    }
  }

  Future<Uint8List?> _compressImage(File file) async {
    // Kompres file image ke kualitas 70 (bisa disesuaikan)
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 70,
      format: CompressFormat.jpeg,
    );
    return result != null ? Uint8List.fromList(result) : null;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      File file = File(picked.path);

      // Kompres dulu image
      final compressedBytes = await _compressImage(file);
      if (compressedBytes != null) {
        setState(() {
          _pickedImageFile = file;
          _profilePictureBytes = compressedBytes;
        });
      } else {
        // Jika compress gagal, tetap pakai original
        final originalBytes = await file.readAsBytes();
        setState(() {
          _pickedImageFile = file;
          _profilePictureBytes = originalBytes;
        });
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    setState(() {
      _pickedImageFile = null;
      _profilePictureBytes = null;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String base64ProfilePicture = '';
      if (_profilePictureBytes != null) {
        base64ProfilePicture = base64Encode(_profilePictureBytes!);
      }

      // Update profile di Firestore
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'username': _nameController.text.trim(),
        'profileDescription': _descController.text.trim(),
        'profilePictureBase64': base64ProfilePicture,
      }, SetOptions(merge: true));

      // Update email di Firebase Auth jika berubah
      if (_emailController.text.trim() != _currentUser!.email) {
        await _currentUser!.updateEmail(_emailController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          _profilePictureBytes != null ? MemoryImage(_profilePictureBytes!) : null,
                      child: _profilePictureBytes == null
                          ? Icon(Icons.person, size: 70, color: Colors.grey.shade600)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (_profilePictureBytes == null)
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A55CA),
                          shape: RoundedRectangleBorder(borderRadius: borderRadius),
                        ),
                        child: Text('Masukkan Profile Picture',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                      ),
                    if (_profilePictureBytes != null) ...[
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A55CA),
                          shape: RoundedRectangleBorder(borderRadius: borderRadius),
                        ),
                        child: Text('Edit Profile Picture',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _removeProfilePicture,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(borderRadius: borderRadius),
                        ),
                        child: Text('Remove Profile Picture',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(borderRadius: borderRadius),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Profile Description',
                        border: OutlineInputBorder(borderRadius: borderRadius),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: borderRadius),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A55CA),
                          shape: RoundedRectangleBorder(borderRadius: borderRadius),
                        ),
                        child: Text('Save Changes',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
