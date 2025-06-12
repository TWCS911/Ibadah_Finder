import 'package:fasum/screens/sign_in_screen.dart';
import 'package:fasum/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class CoverScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'images/logo.png', // Ganti dengan path file gambar kamu
                width: 200,
                height: 200,
              ),
              // Title
              Text(
                'Ibadah Finder',
                style: GoogleFonts.inter(
                      fontSize: 35.0,
                      fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                'Temukan tempat ibadah favorit yang ada\ndi dekatmu dengan mudah',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
                // Login Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const
                                SignInScreen()),
                              );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5A55CA), // warna ungu biru dari gambar
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 20), // Sesuaikan padding agar serupa dengan TextFormField
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white
                ),
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sign Up Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const
                                SignUpScreen()),
                              );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF1F3FF), // warna ungu biru dari gambar
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 20), // Sesuaikan padding agar serupa dengan TextFormField
                  ),
                  child: Text(
                    'Register',
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A55CA)
                    ),
                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
