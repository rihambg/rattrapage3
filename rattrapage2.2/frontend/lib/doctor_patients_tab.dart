import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'doctor_patient_profile_page.dart';
import 'doctor_profile_dialog.dart';

const String apiBase = "http://192.168.1.36:5000";

// --- App color scheme (matches login/register/doctor home pages) ---
const Color kPastelBlue = Color(0xFF2CA7A3);
const Color kPastelGreen = Color(0xFF4B8246);
const Color kPastelPeach = Color(0xFFEB7B64);
const Color kPastelYellow = Color(0xFFD1AC00);
const Color kPastelLilac = Color(0xFF7A5FA0);
const Color kMutedDarkGreen = Color(0xFF297A6C);
const Color kBG = Colors.white;
const Color kCardBG = Color(0xFFF7F7F7);

class DoctorPatientsTab extends StatefulWidget {
  final int doctorId;
  final Function(Map<String, dynamic>) onPatientChatSelected;
  const DoctorPatientsTab({
    required this.doctorId,
    required this.onPatientChatSelected,
  });

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  List<Map<String, dynamic>> patients = [];
  bool loading = false;
  String searchText = "";

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  void fetchPatients() async {
    setState(() => loading = true);
    final res = await http.get(
      Uri.parse("$apiBase/patients/${widget.doctorId}"),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(
        () => patients = List<Map<String, dynamic>>.from(jsonDecode(res.body)),
      );
    }
    setState(() => loading = false);
  }

  List<Map<String, dynamic>> get filteredPatients {
    if (searchText.isEmpty) return patients;
    return patients.where((p) {
      final name = (p['name'] ?? '').toLowerCase();
      final email = (p['email'] ?? '').toLowerCase();
      final city = (p['city'] ?? '').toLowerCase();
      return name.contains(searchText.toLowerCase()) ||
          email.contains(searchText.toLowerCase()) ||
          city.contains(searchText.toLowerCase());
    }).toList();
  }

  // Assign pastel colors to avatars in a cyclic fashion for visual variety
  Color _avatarBgColor(int idx) {
    final colors = [
      kPastelBlue,
      kPastelPeach,
      kPastelGreen,
      kPastelLilac,
      kPastelYellow,
    ];
    return colors[idx % colors.length].withOpacity(0.12);
  }

  Color _avatarIconColor(int idx) {
    final colors = [
      kPastelBlue,
      kPastelPeach,
      kPastelGreen,
      kPastelLilac,
      kPastelYellow,
    ];
    return colors[idx % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBG,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Patients",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: kMutedDarkGreen,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by name, email, or city',
                labelStyle: TextStyle(color: kMutedDarkGreen.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: kPastelBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kPastelBlue.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: kMutedDarkGreen, width: 2),
                ),
                filled: true,
                fillColor: kCardBG,
              ),
              style: TextStyle(color: kMutedDarkGreen),
              onChanged: (v) => setState(() => searchText = v),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: loading
                  ? Center(
                      child: CircularProgressIndicator(color: kMutedDarkGreen))
                  : filteredPatients.isEmpty
                      ? Center(
                          child: Text(
                            "No patients assigned.",
                            style: TextStyle(
                              color: kMutedDarkGreen.withOpacity(0.29),
                              fontSize: 18,
                            ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width < 800 ? 1 : 2,
                            childAspectRatio: 2.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredPatients.length,
                          itemBuilder: (context, i) {
                            final p = filteredPatients[i];
                            return Material(
                              color: kCardBG,
                              elevation: 2,
                              borderRadius: BorderRadius.circular(18),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _avatarBgColor(i),
                                  child: Icon(
                                    Icons.person,
                                    color: _avatarIconColor(i),
                                  ),
                                ),
                                title: Text(
                                  p['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kMutedDarkGreen,
                                  ),
                                ),
                                subtitle: Text(
                                  "${p['email']}\n${p['city'] ?? ''}${p['country'] != null ? ', ${p['country']}' : ''}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kMutedDarkGreen.withOpacity(0.75),
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_red_eye,
                                        color: kPastelLilac,
                                      ),
                                      tooltip: "View Profile",
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              DoctorPatientProfilePage(
                                            doctorId: widget.doctorId,
                                            patientId: p['id'],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.chat,
                                        color: kPastelBlue,
                                      ),
                                      tooltip: "Chat",
                                      onPressed: () =>
                                          widget.onPatientChatSelected(p),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
