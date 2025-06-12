import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/cover_screen.dart';
import 'package:fasum/screens/edit_profile_screen.dart';
import 'package:fasum/screens/preference_settings_screen.dart';
import 'package:fasum/screens/reset_password_screen.dart';
import 'package:fasum/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String profileDescription = '';
  Uint8List? profilePicture;

  bool isLoading = true;

  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => CoverScreen()),
    );
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) {
      setStateIfMounted(() {
        isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setStateIfMounted(() {
          username = data['username'] ?? '';
          profileDescription = data['profileDescription'] ?? '';
          final base64Image = data['profilePictureBase64'] ?? '';
          
          // Menampilkan log untuk melihat isi dari base64Image
          print('Base64 Image: $base64Image');
          
          if (base64Image.isNotEmpty) {
            try {
              profilePicture = base64Decode(base64Image);
            } catch (e) {
              profilePicture = null;
              print('Error decoding base64: $e');
            }
          } else {
            profilePicture = null;
          }
          isLoading = false;
        });
      } else {
        setStateIfMounted(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setStateIfMounted(() {
        isLoading = false;
      });
    }
  }

  // This method checks if the widget is still mounted before calling setState
  void setStateIfMounted(void Function() fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _navigateToEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    _fetchUserData();
  }

  Future<void> _navigateToPreferenceSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PreferenceSettingsScreen()),
    );
  }

  Future<void> _navigateToResetPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        profilePicture != null ? MemoryImage(profilePicture!) : null,
                    child: profilePicture == null
                        ? Icon(Icons.person, size: 70, color: Colors.grey.shade600)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username.isNotEmpty ? username : 'No username set',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileDescription.isNotEmpty
                        ? profileDescription
                        : 'No profile description',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _navigateToEditProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A55CA),
                        shape: RoundedRectangleBorder(borderRadius: borderRadius),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _navigateToPreferenceSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A55CA),
                        shape: RoundedRectangleBorder(borderRadius: borderRadius),
                      ),
                      child: Text(
                        'Preference Settings',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _navigateToResetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A55CA),
                        shape: RoundedRectangleBorder(borderRadius: borderRadius),
                      ),
                      child: Text(
                        'Reset Password',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => signOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: borderRadius),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
