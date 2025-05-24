import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// --- App color scheme (matches all pages) ---
const Color kPastelBlue = Color(0xFF2CA7A3);
const Color kPastelGreen = Color(0xFF4B8246);
const Color kPastelPeach = Color(0xFFEB7B64);
const Color kPastelYellow = Color(0xFFD1AC00);
const Color kPastelLilac = Color(0xFF7A5FA0);
const Color kMutedDarkGreen = Color(0xFF297A6C);
const Color kBG = Colors.white;
const Color kCardBG = Color(0xFFF7F7F7);

const String apiBase = "http://192.168.1.36:5000";

class DoctorChallengesTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  const DoctorChallengesTab({required this.doctor, Key? key}) : super(key: key);

  @override
  State<DoctorChallengesTab> createState() => _DoctorChallengesTabState();
}

class _DoctorChallengesTabState extends State<DoctorChallengesTab> {
  List<Map<String, dynamic>> challenges = [];
  bool loading = false;

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchChallenges();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchChallenges() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$apiBase/challenges"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() {
        challenges = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      });
    }
    setState(() => loading = false);
  }

  Future<void> addChallenge() async {
    if ([titleCtrl, descCtrl, startCtrl, endCtrl].any((c) => c.text.isEmpty))
      return;

    await http.post(
      Uri.parse("$apiBase/challenges"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "creator_id": widget.doctor['id'],
        "title": titleCtrl.text,
        "description": descCtrl.text,
        "start_date": startCtrl.text,
        "end_date": endCtrl.text,
      }),
    );

    titleCtrl.clear();
    descCtrl.clear();
    startCtrl.clear();
    endCtrl.clear();
    fetchChallenges();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPastelBlue,
              onPrimary: Colors.white,
              onSurface: kMutedDarkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // Pastel color cycling for challenge cards
  Color _pastelByIdx(int idx) {
    final colors = [
      kPastelBlue,
      kPastelPeach,
      kPastelGreen,
      kPastelLilac,
      kPastelYellow
    ];
    return colors[idx % colors.length];
  }

  IconData _iconByIdx(int idx) {
    final icons = [
      Icons.flag,
      Icons.restaurant_menu,
      Icons.favorite,
      Icons.remove_red_eye,
      Icons.check_circle,
      Icons.star,
    ];
    return icons[idx % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Create Challenge ----
              Text(
                'Create Challenge',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kMutedDarkGreen,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: kCardBG,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildField(
                        controller: titleCtrl,
                        label: 'Title',
                        icon: Icons.flag,
                        iconColor: kPastelBlue,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: descCtrl,
                        label: 'Description',
                        icon: Icons.description,
                        iconColor: kPastelPeach,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start (YYYY-MM-DD)',
                                prefixIcon: Icon(
                                  Icons.date_range,
                                  color: kPastelGreen,
                                ),
                                filled: true,
                                fillColor: kCardBG,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onTap: () => _pickDate(startCtrl),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: endCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End (YYYY-MM-DD)',
                                prefixIcon: Icon(
                                  Icons.date_range,
                                  color: kPastelLilac,
                                ),
                                filled: true,
                                fillColor: kCardBG,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onTap: () => _pickDate(endCtrl),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: addChallenge,
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text('Add Challenge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPastelBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Ongoing Challenges ----
              const SizedBox(height: 24),
              Text(
                'Ongoing Challenges',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kMutedDarkGreen,
                ),
              ),
              const SizedBox(height: 12),
              if (loading)
                const Center(
                    child: CircularProgressIndicator(color: kMutedDarkGreen))
              else if (challenges.isEmpty)
                Center(
                  child: Text(
                    'No challenges at the moment.',
                    style: TextStyle(
                      fontSize: 16,
                      color: kMutedDarkGreen.withOpacity(0.38),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: challenges.length,
                  itemBuilder: (context, i) {
                    final c = challenges[i];
                    return _ChallengeCard(
                      challenge: c,
                      color: _pastelByIdx(i),
                      icon: _iconByIdx(i),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kMutedDarkGreen.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: kCardBG,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: iconColor, width: 2),
        ),
      ),
      style: TextStyle(color: kMutedDarkGreen),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final Color color;
  final IconData icon;
  const _ChallengeCard(
      {required this.challenge,
      required this.color,
      required this.icon,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final start = challenge['start_date'] ?? '';
    final end = challenge['end_date'] ?? '';
    // Instead of Row, use a Column or wrap long lines to avoid overflow
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: kCardBG,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.18),
                  child: Icon(icon, color: color, size: 25),
                ),
                const SizedBox(width: 12),
                // Wrap the title in Flexible to avoid overflow
                Flexible(
                  child: Text(
                    challenge['title'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kMutedDarkGreen,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge['description'] ?? '',
              style: TextStyle(
                  fontSize: 14, color: kMutedDarkGreen.withOpacity(0.8)),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // This Row is usually the cause of overflow. Use Wrap to allow line breaks.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, color: color, size: 18),
                    const SizedBox(width: 7),
                    Text(
                      'Start: $start',
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, color: color, size: 18),
                    const SizedBox(width: 7),
                    Text(
                      'End: $end',
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
