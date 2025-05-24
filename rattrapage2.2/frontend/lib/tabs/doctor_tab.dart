import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../patient_home_type1type2.dart';
import '../patient_home_prediabetes.dart';
import '../patient_home_gestational.dart';
import '../doctor_profile_page.dart';

const String apiBase = "http://192.168.1.36:5000";

class DoctorTab extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? myDoctor;
  final VoidCallback onDoctorChanged;
  final String? diabetesType;
  const DoctorTab({
    required this.user,
    required this.myDoctor,
    required this.onDoctorChanged,
    this.diabetesType,
    Key? key,
  }) : super(key: key);

  @override
  State<DoctorTab> createState() => _DoctorTabState();
}

class _DoctorTabState extends State<DoctorTab> {
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  List<Map<String, dynamic>> specialties = [];
  List<String> cities = [];
  bool loadingDoctors = false;
  String searchText = "";
  String specialtyText = "";
  String cityText = "";

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchSpecialties();
    fetchDoctors();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void fetchSpecialties() async {
    final res = await http.get(Uri.parse("$apiBase/specialties"));
    if (res.statusCode == 200) {
      setState(() {
        specialties = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      });
    }
  }

  void fetchDoctors() async {
    setState(() => loadingDoctors = true);
    final res = await http.get(Uri.parse("$apiBase/doctors"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      final d = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      final citySet = d
          .map((doc) => doc['city'] ?? '')
          .where((c) => c != null && c.toString().isNotEmpty)
          .toSet()
          .toList();
      setState(() {
        doctors = d;
        filteredDoctors = d;
        cities = List<String>.from(citySet)..sort();
      });
    }
    setState(() => loadingDoctors = false);
  }

  void assignDoctor(int doctorId) async {
    await http.post(Uri.parse("$apiBase/assign_doctor"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "doctor_id": doctorId,
          "patient_id": widget.user['id'],
        }));
    widget.onDoctorChanged();
    fetchDoctors();
  }

  void filterDoctors() {
    setState(() {
      filteredDoctors = doctors.where((d) {
        final nameMatch =
            (d['name'] ?? '').toLowerCase().contains(searchText.toLowerCase());
        final specialtyMatch = specialtyText.isEmpty
            ? true
            : (d['specialty'] ?? '').toString().toLowerCase() ==
                specialtyText.toLowerCase();
        final cityMatch = cityText.isEmpty
            ? true
            : (d['city'] ?? '').toString().toLowerCase() ==
                cityText.toLowerCase();
        return (searchText.isEmpty || nameMatch) && specialtyMatch && cityMatch;
      }).toList();
    });
  }

  void openDoctorProfile(Map<String, dynamic> doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorProfilePage(doctorId: doctor['id']),
      ),
    );
  }

  void goToCorrectHome(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            goToCorrectHome(context);
          },
        ),
        title: Text('Doctors Tab'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("My Doctor:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.blue[900])),
                    if (widget.myDoctor != null &&
                        widget.myDoctor!['name'] != null)
                      Card(
                        color: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[200],
                            child: Icon(Icons.person, color: Colors.blue[800]),
                          ),
                          title: Text(widget.myDoctor?['name'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(widget.myDoctor?['email'] ?? ''),
                          trailing:
                              Icon(Icons.verified, color: Colors.green, size: 28),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text("No doctor assigned.",
                            style: TextStyle(color: Colors.grey[700])),
                      ),
                    SizedBox(height: 16),
                    Text("Find & Assign Doctor:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.blue[900])),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                                labelText: 'Search by name',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16))),
                            onChanged: (v) {
                              searchText = v;
                              filterDoctors();
                            },
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: specialtyText.isEmpty ? null : specialtyText,
                            decoration: InputDecoration(
                              labelText: "Filter by specialty",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: "",
                                child: Text("All Specialties"),
                              ),
                              ...specialties.map((s) => DropdownMenuItem(
                                    value: s["name"],
                                    child: Text(s["name"]),
                                  )),
                            ],
                            onChanged: (v) {
                              specialtyText = v ?? "";
                              filterDoctors();
                            },
                            isExpanded: true,
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: cityText.isEmpty ? null : cityText,
                            decoration: InputDecoration(
                              labelText: "Filter by city",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: "",
                                child: Text("All Cities"),
                              ),
                              ...cities.map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  )),
                            ],
                            onChanged: (v) {
                              cityText = v ?? "";
                              filterDoctors();
                            },
                            isExpanded: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (loadingDoctors)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredDoctors.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 100),
                    child: Text(
                      "No doctors found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width < 600 ? 1 : 2,
                    childAspectRatio: 2.5, // slightly lower for more height
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final d = filteredDoctors[i];
                      return GestureDetector(
                        onTap: () => openDoctorProfile(d),
                        child: DoctorCard(
                          doctor: d,
                          assign: () => assignDoctor(d['id']),
                          isAssigned: widget.myDoctor != null &&
                              widget.myDoctor!['id'] == d['id'],
                        ),
                      );
                    },
                    childCount: filteredDoctors.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback assign;
  final bool isAssigned;
  const DoctorCard({
    required this.doctor,
    required this.assign,
    required this.isAssigned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isAssigned ? 6 : 2,
      shadowColor: isAssigned ? Colors.greenAccent : Colors.blueGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isAssigned ? Colors.green[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 28, color: Colors.blue[700]),
            ),
            SizedBox(width: 16),
            // Use Flexible for info column to prevent overflows from long text
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // prevents overflow
                children: [
                  Text(
                    doctor['name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${doctor['specialty'] ?? ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${doctor['city'] ?? ''}, ${doctor['country'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    doctor['email'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            isAssigned
                ? Icon(Icons.verified, color: Colors.green, size: 32)
                : ElevatedButton(
                    onPressed: assign,
                    child: Text("Assign"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}