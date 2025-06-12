import 'package:fasum/screens/main_screen.dart';
import 'package:fasum/screens/sign_in_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fasum/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  SignUpScreenState createState() => SignUpScreenState();
}
class SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: GoogleFonts.inter(
                    fontSize: 36.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13.0),

                    Text(
                    'Create your account to get started',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                    ),
                  const SizedBox(height: 50.0),
                  TextFormField(
                    controller: _usernameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                    return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null ||
                        value.isEmpty ||
                        !_isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                       return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16.0),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C63D2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                        ),
                        ),
                        child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.white, // Font berwarna putih
                          fontWeight: FontWeight.bold, fontSize: 20.0
                        ),
                        ),
                      ),
                      ),
                  
                  const SizedBox(height: 16.0),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16.0, color: textColor), // Warna teks mengikuti tema
                      children: [
                        const TextSpan(text: "Already have an account? "),
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(
                            color: Colors.blue, // Tetap berwarna biru
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignInScreen()),
                              );
                            },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Pastikan currentUser sudah aktif dan sama dengan user baru
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != userCredential.user!.uid) {
        throw FirebaseAuthException(
          code: 'user-not-logged-in',
          message: 'User not logged in after registration.',
        );
      }

      // Simpan data user ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': _usernameController.text.trim(),
        'email': email,
        'createdAt': Timestamp.now(),
      });

      // Navigasi ke HomeScreen dan hapus semua route sebelumnya
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
        (route) => false,
      );

    } on FirebaseAuthException catch (error) {
      _showErrorMessage(_getAuthErrorMessage(error.code));
    } catch (error) {
      // Bisa juga cek kalau error Firestore permission denied
      if (error.toString().contains('permission-denied')) {
        _showErrorMessage('You do not have permission to save user data. Please check Firestore rules.');
      } else {
        _showErrorMessage('An error occurred: $error');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
  bool _isValidEmail(String email) {
    String emailRegex =
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zAZ0-9-]+)*$";
    return RegExp(emailRegex).hasMatch(email);
  }
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
      return 'The password provided is too weak.';
      case 'email-already-in-use':
      return 'The account already exists for that email.';
      case 'invalid-email':
      return 'The email address is not valid.';
      default:
      return 'An error occurred. Please try again.';
    }
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}