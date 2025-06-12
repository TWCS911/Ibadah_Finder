import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  File? _pickedImageFile;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _locationSaved = false;

  final ImagePicker _picker = ImagePicker();

  double? _latitude;
  double? _longitude;

  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _pickedImageFile = File(image.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')));
      setState(() {
        _isGettingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')));
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, please enable it from settings')));
      setState(() {
        _isGettingLocation = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationSaved = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  /// Fungsi kompres gambar dengan flutter_image_compress
  Future<List<int>?> _compressImage(File file) async {
    return await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 70, // kualitas 0-100
      minWidth: 800, // maksimal lebar
      minHeight: 600, // maksimal tinggi
      format: CompressFormat.jpeg,
    );
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')));
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please get your current location')));
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kompres gambar terlebih dahulu
      final compressedBytes = await _compressImage(_pickedImageFile!);
      if (compressedBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to compress image')));
        setState(() => _isLoading = false);
        return;
      }

      String imageBase64String = base64Encode(compressedBytes);

      await FirebaseFirestore.instance.collection('locations').add({
        'name': _nameController.text.trim().toLowerCase(), // Menyimpan nama sebagai lowercase
        'description': _descController.text.trim(),
        'imageBase64': imageBase64String,
        'rating': 0.0,
        'reviews': [],
        'latitude': _latitude,
        'longitude': _longitude,
        'uploadedByUid': currentUser.uid,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location added successfully')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error adding location: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Add Location', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  border: OutlineInputBorder(borderRadius: borderRadius),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter location name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: borderRadius),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter description' : null,
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Location Photo',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickedImageFile == null ? _pickImage : null,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(color: Colors.grey.shade400),
                    color: Colors.grey.shade100,
                  ),
                  child: _pickedImageFile != null
                      ? ClipRRect(
                          borderRadius: borderRadius,
                          child: Image.file(_pickedImageFile!, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _locationSaved || _isGettingLocation ? null : _getCurrentLocation,
                icon: _locationSaved
                    ? const Icon(Icons.check, color: Colors.white)
                    : (_isGettingLocation
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location, color: Colors.white)),
                label: Text(
                  _locationSaved ? 'Berhasil menyimpan' : 'Add Location',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return const Color(0xFF5A55CA);
                    }
                    return const Color(0xFF5A55CA);
                  }),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: borderRadius,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: borderRadius,
                        ),
                        backgroundColor: const Color(0xFF4C63D2),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
