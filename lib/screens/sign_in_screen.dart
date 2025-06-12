import 'package:fasum/screens/main_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fasum/screens/sign_up_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  SignInScreenState createState() => SignInScreenState();
}
class SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false
      ),
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
                    'Access Account',
                    style: GoogleFonts.inter(
                    fontSize: 36.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13.0),

                    Text(
                    'Welcome back! Please log in to access your account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                    ),
                  const SizedBox(height: 50.0),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),

                    validator: (value) {

                      if (value == null || value.isEmpty ||
                          !_isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }

                      return null;

                    },
                  ),

                  const SizedBox(height: 16.0),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),

                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility :
                        Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),

                    validator: (value) {

                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
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
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C63D2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Kotak
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                        ),
                        ),
                        child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.white, // Font berwarna putih
                          fontWeight: FontWeight.bold, fontSize: 20.0
                        ),
                        ),
                      ),
                      ),
                    const SizedBox(height: 16.0),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade400,
                          thickness: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'OR',
                          style: GoogleFonts.inter(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade400,
                          thickness: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16.0, color: textColor), // Warna teks mengikuti tema
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: Colors.blue, // Tetap berwarna biru
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
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
  void _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } on FirebaseAuthException catch (error) {
      _showSnackBar(_getAuthErrorMessage(error.code));
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  bool _isValidEmail(String email) {
    String emailRegex =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";
    return RegExp(emailRegex).hasMatch(email);
  }
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with that email';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}