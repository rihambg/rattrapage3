import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'patient_home.dart';
import 'doctor_home.dart';
import 'register_patient.dart';
import 'register_doctor.dart';
import 'patient_home_gestational.dart';
import 'patient_home_type1type2.dart';
import 'patient_home_prediabetes.dart';

const String apiBase = "http://192.168.1.36:5000";

// Muted dark green accent for all highlights and buttons
const Color kDarkerGreen = Color(0xFF297A6C); // Muted, dark logo green accent
const Color kCardBG = Color(
    0xFFF7F7F7); // Subtle off-white for cards (optional, can be Colors.white)
const Color kWhiteBG = Colors.white; // Main background

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: kDarkerGreen.withOpacity(0.52)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.89),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: kDarkerGreen.withOpacity(0.13)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: kDarkerGreen.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: kDarkerGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Please enter both email and password.");
      return;
    }

    setState(() {
      _error = '';
      _isLoading = true;
    });

    try {
      final res = await http.post(
        Uri.parse("$apiBase/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final user = jsonDecode(res.body);
        if (user['role'] == 'doctor') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DoctorHome(user: user)),
            (route) => false,
          );
        } else {
          final profRes = await http
              .get(Uri.parse("$apiBase/patient_profile/${user['id']}"));
          if (profRes.statusCode == 200) {
            final profile = jsonDecode(profRes.body);
            final diabetesType = (profile['diabetes_type'] ?? '').toString();
            Widget home;
            if (diabetesType == "Gestational") {
              home = PatientHomeGestational(user: user, profile: profile);
            } else if (diabetesType == "Type 1" || diabetesType == "Type 2") {
              home = PatientHomeType1Type2(user: user, profile: profile);
            } else if (diabetesType == "Prediabetes") {
              home = PatientHomePrediabetes(user: user, profile: profile);
            } else {
              home = PatientHome(user: user);
            }
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => home),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => PatientHome(user: user)),
              (route) => false,
            );
          }
        }
      } else {
        final err = jsonDecode(res.body);
        setState(() => _error = err['message'] ?? 'Invalid login.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteBG,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 34),
              // Logo (rounded square, no Sukari, just logo and slogan)
              Container(
                alignment: Alignment.center,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: kCardBG,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: kDarkerGreen.withOpacity(0.23), width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: kDarkerGreen.withOpacity(0.08),
                        spreadRadius: 2,
                        blurRadius: 18,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image.asset(
                      "assets/sukari_logo.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              // Slogan only, bold and green
              Text(
                'Sweet support for a balanced life',
                style: GoogleFonts.poppins(
                  color: kDarkerGreen,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Login Card (off-white box, subtle shadow)
              Card(
                color: kCardBG,
                elevation: 8,
                shadowColor: kDarkerGreen.withOpacity(0.09),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          color: kDarkerGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              color: kDarkerGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Email',
                            style: GoogleFonts.poppins(
                              color: kDarkerGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _emailController,
                        decoration: _inputDecoration('Enter your email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.lock_outline,
                              color: kDarkerGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Password',
                            style: GoogleFonts.poppins(
                              color: kDarkerGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration:
                            _inputDecoration('Enter your password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: kDarkerGreen,
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      if (_error.isNotEmpty)
                        Text(
                          _error,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12),
                        ),
                      if (_error.isNotEmpty) const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _login,
                        child: Container(
                          width: double.infinity,
                          height: 47,
                          decoration: BoxDecoration(
                            color: kDarkerGreen,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: kDarkerGreen.withOpacity(0.12),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    'LOGIN',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      // Register buttons one under the other
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RegisterPatientScreen()),
                        ),
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Register as Patient'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kDarkerGreen,
                          side: BorderSide(color: kDarkerGreen, width: 1.3),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500, fontSize: 15),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RegisterDoctorScreen()),
                        ),
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Register as Doctor'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kDarkerGreen,
                          side: BorderSide(color: kDarkerGreen, width: 1.3),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500, fontSize: 15),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Optional grid accent at the bottom
              SizedBox(
                width: double.infinity,
                height: 40,
                child: CustomPaint(
                  painter: _PastelGridPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle grid for background accent at the bottom
class _PastelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kDarkerGreen.withOpacity(0.06)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 22) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 10) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
    paint.color = kDarkerGreen.withOpacity(0.09);
    canvas.drawCircle(Offset(size.width - 18, size.height / 2), 7, paint);
    paint.color = kDarkerGreen.withOpacity(0.08);
    canvas.drawCircle(Offset(18, size.height - 8), 6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
