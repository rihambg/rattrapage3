import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String apiBase = "http://192.168.1.36:5000";

class PregnancyTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const PregnancyTab({required this.user, Key? key}) : super(key: key);

  @override
  State<PregnancyTab> createState() => _PregnancyTabState();
}

class _PregnancyTabState extends State<PregnancyTab> {
  DateTime? lmpDate;
  DateTime? customEDD;
  String eddSource = "LMP";
  int gestationalWeek = 0;
  int gestationalDay = 0;
  DateTime? edd;
  List<Map<String, dynamic>> fetalNotes = [];
  List<Map<String, dynamic>> kicks = [];
  bool loading = true;
  TextEditingController _noteController = TextEditingController();

  // Fetal development info (simple static data for demo, you can expand this!)
  List<Map<String, String>> fetalDevelopment = [
    {
      "week": "1-4",
      "size": "Poppy seed",
      "info": "Implantation, basic cell layers form."
    },
    {
      "week": "5",
      "size": "Sesame seed",
      "info": "Heart and neural tube begin forming."
    },
    {
      "week": "6",
      "size": "Lentil",
      "info": "Heartbeat detected, limb buds appear."
    },
    {
      "week": "7",
      "size": "Blueberry",
      "info": "Facial features and brain growing rapidly."
    },
    {
      "week": "8",
      "size": "Kidney bean",
      "info": "Arms and legs lengthen, fingers develop."
    },
    {
      "week": "9",
      "size": "Grape",
      "info": "All major organs in place, rapid growth."
    },
    {
      "week": "10",
      "size": "Strawberry",
      "info": "Nails form, head is half the body length."
    },
    {
      "week": "12",
      "size": "Lime",
      "info": "Fingers/toes separated, reflexes starting."
    },
    {
      "week": "16",
      "size": "Avocado",
      "info": "Movements stronger, eyes can move."
    },
    {
      "week": "20",
      "size": "Banana",
      "info": "Can hear, hair and nails growing."
    },
    {
      "week": "24",
      "size": "Ear of corn",
      "info": "Lungs developing, skin less transparent."
    },
    {"week": "28", "size": "Eggplant", "info": "Eyes open, brain very active."},
    {"week": "32", "size": "Squash", "info": "Bones harden, kicks stronger."},
    {
      "week": "36",
      "size": "Honeydew melon",
      "info": "Body fat increases, organs mature."
    },
    {"week": "40", "size": "Watermelon", "info": "Full term! Ready for birth."},
  ];

  @override
  void initState() {
    super.initState();
    fetchPregnancyData();
  }

  /// Try to parse backend date as either ISO8601 or legacy formats.
  DateTime? tryParseDate(String? str) {
    if (str == null) return null;
    try {
      // Try ISO8601 first
      return DateTime.parse(str);
    } catch (_) {
      // Try other formats, e.g. "Fri May 2025 18:29:21 GMT"
      try {
        return DateFormat('EEE MMM yyyy HH:mm:ss')
            .parseUtc(str.replaceAll('GMT', '').trim());
      } catch (_) {
        // Try RFC 1123
        try {
          return DateFormat('EEE, dd MMM yyyy HH:mm:ss')
              .parseUtc(str.replaceAll('GMT', '').trim());
        } catch (_) {
          // Try a looser format
          try {
            // Remove weekday if present
            var parts = str.split(' ');
            if (parts.length >= 6) {
              // e.g. "Fri May 2025 18:29:21 GMT"
              var dateOnly = "${parts[1]} ${parts[2]} ${parts[3]} ${parts[4]}";
              return DateFormat('MMM yyyy HH:mm:ss').parseUtc(dateOnly);
            }
          } catch (_) {}
        }
      }
    }
    return null;
  }

  Future<void> fetchPregnancyData() async {
    setState(() => loading = true);
    // Get pregnancy info (LMP, EDD) from backend if available
    final res =
        await http.get(Uri.parse('$apiBase/pregnancy/${widget.user['id']}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        String? lmpStr = data['lmp_date'];
        String? eddStr = data['edd'];
        String? eddSrc = data['edd_source'];
        if (lmpStr != null) lmpDate = tryParseDate(lmpStr);
        if (eddStr != null) edd = tryParseDate(eddStr);
        if (eddSrc != null) eddSource = eddSrc;
        customEDD = eddSource == "Custom" ? edd : null;
      });
    }
    // Get fetal notes
    final notesRes = await http
        .get(Uri.parse('$apiBase/pregnancy/${widget.user['id']}/notes'));
    if (notesRes.statusCode == 200) {
      fetalNotes = List<Map<String, dynamic>>.from(jsonDecode(notesRes.body));
    }
    // Get kicks
    final kicksRes = await http
        .get(Uri.parse('$apiBase/pregnancy/${widget.user['id']}/kicks'));
    if (kicksRes.statusCode == 200) {
      kicks = List<Map<String, dynamic>>.from(jsonDecode(kicksRes.body));
    }
    setState(() {
      loading = false;
    });
    computeGestationalAge();
  }

  void computeGestationalAge() {
    if (edd != null) {
      final today = DateTime.now();
      final conceptionDate = edd!.subtract(const Duration(days: 280));
      final diff = today.difference(conceptionDate);
      gestationalWeek = (diff.inDays / 7).floor().clamp(0, 40);
      gestationalDay = (diff.inDays % 7).clamp(0, 6);
    } else if (lmpDate != null) {
      final today = DateTime.now();
      final diff = today.difference(lmpDate!);
      gestationalWeek = (diff.inDays / 7).floor().clamp(0, 40);
      gestationalDay = (diff.inDays % 7).clamp(0, 6);
      edd = lmpDate!.add(const Duration(days: 280));
    }
  }

  Future<void> savePregnancyData() async {
    setState(() => loading = true);
    final res = await http.post(
      Uri.parse('$apiBase/pregnancy/${widget.user['id']}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "lmp_date": lmpDate?.toIso8601String(),
        "edd": edd?.toIso8601String(),
        "edd_source": eddSource,
      }),
    );
    setState(() => loading = false);
    if (res.statusCode == 200) {
      computeGestationalAge();
    }
  }

  Future<void> addFetalNote() async {
    if (_noteController.text.trim().isEmpty) return;
    final res = await http.post(
      Uri.parse('$apiBase/pregnancy/${widget.user['id']}/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "note": _noteController.text.trim(),
      }),
    );
    if (res.statusCode == 200) {
      _noteController.clear();
      fetchPregnancyData();
    }
  }

  Future<void> addKick() async {
    final res = await http.post(
      Uri.parse('$apiBase/pregnancy/${widget.user['id']}/kicks'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      fetchPregnancyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    computeGestationalAge();
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.pink[800],
        elevation: 1,
        title: const Text("Pregnancy Tracker"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline & EDD section
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Pregnancy Timeline",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.pink),
                          ),
                          const SizedBox(height: 10),
                          _timelineSection(context),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Fetal dev section
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Fetal Development This Week",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.pink),
                          ),
                          const SizedBox(height: 10),
                          _fetalDevelopmentSection(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Kick counter
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: _kickCounterSection(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Notes section
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: _notesSection(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _timelineSection(BuildContext context) {
    String gestText = (gestationalWeek > 0)
        ? "Week $gestationalWeek day $gestationalDay"
        : "Not set";
    String eddText =
        (edd != null) ? DateFormat("d MMM yyyy").format(edd!) : "Not set";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gestational Age:",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Row(
          children: [
            Text(
              gestText,
              style: TextStyle(
                  color: Colors.pink[700],
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 15),
            _progressBar(gestationalWeek, context),
          ],
        ),
        const SizedBox(height: 10),
        Text("Expected Delivery Date:",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        Text(
          eddText,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.pink[700]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.calendar_today),
                label: const Text("Set LMP"),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: lmpDate ??
                        DateTime.now().subtract(const Duration(days: 280 - 7)),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      lmpDate = picked;
                      eddSource = "LMP";
                      edd = lmpDate!.add(const Duration(days: 280));
                      customEDD = null;
                    });
                    savePregnancyData();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.event_available),
                label: const Text("Set EDD"),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        edd ?? DateTime.now().add(const Duration(days: 100)),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 100)),
                    lastDate: DateTime.now().add(const Duration(days: 300)),
                  );
                  if (picked != null) {
                    setState(() {
                      edd = picked;
                      eddSource = "Custom";
                      customEDD = picked;
                    });
                    savePregnancyData();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Tip: LMP = Last Menstrual Period. EDD = Estimated Due Date (from LMP or doctor).",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _progressBar(int week, BuildContext context) {
    double percent = (week / 40).clamp(0.0, 1.0);
    return Expanded(
      child: LinearProgressIndicator(
        value: percent,
        minHeight: 13,
        backgroundColor: Colors.pink[50],
        valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _fetalDevelopmentSection() {
    // Find the closest week to current
    Map<String, String>? weekInfo;
    for (var entry in fetalDevelopment) {
      int? weekNum = int.tryParse(entry["week"]!.split("-").last);
      if (weekNum != null && gestationalWeek <= weekNum) {
        weekInfo = entry;
        break;
      }
    }
    weekInfo ??= fetalDevelopment.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Week: ${weekInfo["week"]}",
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.pink[700]),
        ),
        const SizedBox(height: 3),
        Text("Size: ${weekInfo["size"]}", style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 3),
        Text(weekInfo["info"] ?? "", style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _kickCounterSection() {
    int totalKicks = kicks.length;
    DateTime now = DateTime.now();
    int todayKicks = kicks.where((k) {
      DateTime? dt = tryParseDate(k['timestamp']);
      dt ??= DateTime(2000);
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kick Counter",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pink),
        ),
        const SizedBox(height: 8),
        Text(
          "Monitor fetal movements starting around week 28. Press the button each time you feel a kick.",
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.touch_app, size: 28),
              label: const Text("Record Kick"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: addKick,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Today's kicks",
                      style: const TextStyle(color: Colors.grey)),
                  Text("$todayKicks",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.pink[700])),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Total kicks",
                      style: const TextStyle(color: Colors.grey)),
                  Text("$totalKicks",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.pink[700])),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _notesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Doctor Notes & Anomalies",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pink),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText:
                "Add a note about fetal movement, doctor instructions, etc.",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Colors.pink),
              onPressed: addFetalNote,
            ),
          ),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        ...fetalNotes.reversed.map((n) => Card(
              color: Colors.pink[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                leading: Icon(Icons.note_alt, color: Colors.pink[200]),
                title: Text(n['note'] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: n['timestamp'] != null
                    ? Text(
                        tryParseDate(n['timestamp']) != null
                            ? DateFormat('d MMM yyyy, HH:mm')
                                .format(tryParseDate(n['timestamp'])!.toLocal())
                            : n['timestamp'],
                        style: const TextStyle(fontSize: 12))
                    : null,
              ),
            )),
      ],
    );
  }
}
