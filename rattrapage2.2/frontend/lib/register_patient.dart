import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'location_data.dart';

const String apiBase = "http://192.168.1.36:5000";

// --- Deeper pastel icon colors for contrast ---
const Color kPastelBlue = Color(0xFF2CA7A3);
const Color kPastelGreen = Color(0xFF4B8246);
const Color kPastelPeach = Color(0xFFEB7B64);
const Color kPastelYellow = Color(0xFFD1AC00);
const Color kPastelLilac = Color(0xFF7A5FA0);
const Color kMutedDarkGreen = Color(0xFF297A6C);
const Color kBG = Colors.white;
const Color kCardBG = Color(0xFFF7F7F7);

class RegisterPatientScreen extends StatefulWidget {
  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final regNameCtrl = TextEditingController();
  final regEmailCtrl = TextEditingController();
  final regPassCtrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();
  final patPhoneCtrl = TextEditingController();
  DateTime? patDob;
  String patGender = "M";
  String? patCountryIso2;
  String? patCountryName;
  String? patCity;
  String patDiabetesType = "Prediabetes";
  final patHealthBgCtrl = TextEditingController();
  final patEmergencyNameCtrl = TextEditingController();
  final patEmergencyPhoneCtrl = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String error = '';
  bool loading = false;
  List<Country> countries = [];
  List<City> cities = [];

  @override
  void initState() {
    super.initState();
    LocationDataProvider.loadCountries().then((list) {
      setState(() {
        countries = list;
      });
    });
  }

  Future<void> pickCity(String? countryIso2) async {
    if (countryIso2 == null) return;
    setState(() {
      cities = [];
      patCity = null;
    });
    cities = await LocationDataProvider.loadCities(countryIso2);
    setState(() {});
  }

  void pickDob(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => patDob = picked);
  }

  void autofillEmergency() {
    if (patEmergencyNameCtrl.text.isEmpty && regNameCtrl.text.isNotEmpty) {
      patEmergencyNameCtrl.text = regNameCtrl.text.split(" ").first;
    }
    if (patEmergencyPhoneCtrl.text.isEmpty && patPhoneCtrl.text.isNotEmpty) {
      patEmergencyPhoneCtrl.text = patPhoneCtrl.text;
    }
    setState(() {});
  }

  void register() async {
    setState(() {
      error = "";
      loading = true;
    });
    final res = await http.post(
      Uri.parse("$apiBase/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": regNameCtrl.text.trim(),
        "email": regEmailCtrl.text.trim(),
        "password": regPassCtrl.text,
        "confirm_password": regPass2Ctrl.text,
        "role": "patient",
        "phone": patPhoneCtrl.text,
        "dob": patDob?.toIso8601String().split("T").first,
        "gender": patGender,
        "city": patCity,
        "country": patCountryName,
        "diabetes_type": patDiabetesType,
        "health_background": patHealthBgCtrl.text,
        "emergency_contact_name": patEmergencyNameCtrl.text,
        "emergency_contact_phone": patEmergencyPhoneCtrl.text,
      }),
    );
    setState(() => loading = false);
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() {
        error = "Registration successful! Please login.";
      });
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } else {
      setState(
        () => error =
            "Registration failed: ${jsonDecode(res.body)["error"].toString()}",
      );
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kMutedDarkGreen.withOpacity(0.13)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kMutedDarkGreen.withOpacity(0.09)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kMutedDarkGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  void showCountryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Country'),
          content: Container(
            width: double.maxFinite,
            height: 300, // Fixed height for scrollable list
            child: ListView.builder(
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final country = countries[index];
                return ListTile(
                  title: Text(country.name),
                  onTap: () {
                    setState(() {
                      patCountryIso2 = country.iso2;
                      patCountryName = country.name;
                    });
                    pickCity(country.iso2);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // deeper pastel icon palette for each field, for contrast
  Color _iconColor(int field) {
    switch (field) {
      case 0:
        return kPastelBlue; // person
      case 1:
        return kPastelPeach; // email
      case 2:
        return kPastelGreen; // phone
      case 3:
        return kPastelYellow; // dob
      case 4:
        return kPastelLilac; // gender
      case 5:
        return kPastelBlue; // country
      case 6:
        return kPastelPeach; // city
      case 7:
        return kPastelGreen; // diabetes type
      case 8:
        return kPastelYellow; // health background
      case 9:
        return kPastelLilac; // emergency name
      case 10:
        return kPastelBlue; // emergency phone
      case 11:
        return kPastelPeach; // password
      case 12:
        return kPastelGreen; // confirm password
      default:
        return kMutedDarkGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                alignment: Alignment.center,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: kCardBG,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: kMutedDarkGreen.withOpacity(0.13), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: kMutedDarkGreen.withOpacity(0.06),
                        spreadRadius: 2,
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      "assets/sukari_logo.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sweet support for a balanced life',
                style: GoogleFonts.poppins(
                  color: kMutedDarkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'REGISTER AS PATIENT',
                style: GoogleFonts.poppins(
                  color: kMutedDarkGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your account to get started',
                style: GoogleFonts.poppins(
                  color: kMutedDarkGreen.withOpacity(0.67),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                color: kCardBG,
                elevation: 7,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name
                      Row(
                        children: [
                          Icon(Icons.person, color: _iconColor(0), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Full Name',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: regNameCtrl,
                        decoration: _inputDecoration('Enter your full name'),
                        onChanged: (_) => autofillEmergency(),
                      ),
                      const SizedBox(height: 18),
                      // Email
                      Row(
                        children: [
                          Icon(Icons.email, color: _iconColor(1), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Email',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: regEmailCtrl,
                        decoration: _inputDecoration('Enter your email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 18),
                      // Phone Number
                      Row(
                        children: [
                          Icon(Icons.phone, color: _iconColor(2), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: patPhoneCtrl,
                        decoration: _inputDecoration(
                          'Enter your phone number',
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => autofillEmergency(),
                      ),
                      const SizedBox(height: 18),
                      // Date of Birth
                      Row(
                        children: [
                          Icon(Icons.cake, color: _iconColor(3), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Date of Birth',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        readOnly: true,
                        decoration: _inputDecoration(
                          patDob == null
                              ? 'Select your date of birth'
                              : patDob!.toIso8601String().split("T").first,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.calendar_today,
                              color: kMutedDarkGreen.withOpacity(0.8),
                            ),
                            onPressed: () => pickDob(context),
                          ),
                        ),
                        onTap: () => pickDob(context),
                      ),
                      const SizedBox(height: 18),
                      // Gender
                      Row(
                        children: [
                          Icon(Icons.wc, color: _iconColor(4), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Gender',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: patGender,
                        decoration: _inputDecoration('Select your gender'),
                        items: [
                          DropdownMenuItem(value: "M", child: Text("Male")),
                          DropdownMenuItem(value: "F", child: Text("Female")),
                          DropdownMenuItem(
                            value: "Other",
                            child: Text("Other"),
                          ),
                        ],
                        onChanged: (v) => setState(() => patGender = v!),
                      ),
                      const SizedBox(height: 18),
                      // Country
                      Row(
                        children: [
                          Icon(Icons.flag, color: _iconColor(5), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Country',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: showCountryDialog,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kMutedDarkGreen.withOpacity(0.10),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                patCountryName ?? 'Select your country',
                                style: TextStyle(
                                  color: patCountryName == null
                                      ? Colors.grey
                                      : kMutedDarkGreen,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: kMutedDarkGreen.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // City
                      Row(
                        children: [
                          Icon(
                            Icons.location_city,
                            color: _iconColor(6),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'City',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: patCity,
                        decoration: _inputDecoration('Select your city'),
                        items: cities
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.name,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => patCity = v),
                      ),
                      const SizedBox(height: 18),
                      // Diabetes Type
                      Row(
                        children: [
                          Icon(
                            Icons.bloodtype,
                            color: _iconColor(7),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Diabetes Type',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: patDiabetesType,
                        decoration: _inputDecoration(
                          'Select your diabetes type',
                        ),
                        items: [
                          DropdownMenuItem(
                            value: "Prediabetes",
                            child: Text("Prediabetes"),
                          ),
                          DropdownMenuItem(
                            value: "Type 1",
                            child: Text("Type 1"),
                          ),
                          DropdownMenuItem(
                            value: "Type 2",
                            child: Text("Type 2"),
                          ),
                          DropdownMenuItem(
                            value: "Gestational",
                            child: Text("Gestational"),
                          ),
                        ],
                        onChanged: (v) => setState(() => patDiabetesType = v!),
                      ),
                      const SizedBox(height: 18),
                      // Health Background (optional)
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _iconColor(8),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Health Background (optional)',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: patHealthBgCtrl,
                        decoration: _inputDecoration(
                          'Enter your health background',
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Emergency Contact Name
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin,
                            color: _iconColor(9),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Emergency Contact Name',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: patEmergencyNameCtrl,
                        decoration: _inputDecoration(
                          'Enter emergency contact name',
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Emergency Contact Phone
                      Row(
                        children: [
                          Icon(
                            Icons.phone_in_talk,
                            color: _iconColor(10),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Emergency Contact Phone',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: patEmergencyPhoneCtrl,
                        decoration: _inputDecoration(
                          'Enter emergency contact phone',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      // Password
                      Row(
                        children: [
                          Icon(Icons.lock, color: _iconColor(11), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Password',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: regPassCtrl,
                        obscureText: !_isPasswordVisible,
                        decoration: _inputDecoration(
                          'Enter your password',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: kMutedDarkGreen.withOpacity(0.7),
                            ),
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Confirm Password
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: _iconColor(12),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm Password',
                            style: TextStyle(
                              color: kMutedDarkGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: regPass2Ctrl,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: _inputDecoration(
                          'Confirm your password',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: kMutedDarkGreen.withOpacity(0.7),
                            ),
                            onPressed: () => setState(
                              () => _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (error.isNotEmpty)
                        Text(
                          error,
                          style: TextStyle(
                            color: error.contains("success")
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (loading)
                        Center(child: CircularProgressIndicator())
                      else ...[
                        ElevatedButton(
                          onPressed: register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMutedDarkGreen,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'REGISTER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Back to Login',
                            style: TextStyle(color: kMutedDarkGreen),
                          ),
                        ),
                      ],
                    ],
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
