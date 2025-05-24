import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://192.168.1.36:5000";

// --- App color scheme (matches all pages) ---
const Color kPastelBlue = Color(0xFF2CA7A3);
const Color kPastelGreen = Color(0xFF4B8246);
const Color kPastelPeach = Color(0xFFEB7B64);
const Color kPastelYellow = Color(0xFFD1AC00);
const Color kPastelLilac = Color(0xFF7A5FA0);
const Color kMutedDarkGreen = Color(0xFF297A6C);
const Color kBG = Colors.white;
const Color kCardBG = Color(0xFFF7F7F7);

class DoctorFaqTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  const DoctorFaqTab({required this.doctor});

  @override
  State<DoctorFaqTab> createState() => _DoctorFaqTabState();
}

class _DoctorFaqTabState extends State<DoctorFaqTab> {
  List<Map<String, dynamic>> faqs = [];
  bool loading = false;
  final Map<int, TextEditingController> answerControllers = {};

  @override
  void initState() {
    super.initState();
    fetchFaqs();
  }

  @override
  void dispose() {
    answerControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void fetchFaqs() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse("$apiBase/faqs"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(
        () => faqs = List<Map<String, dynamic>>.from(jsonDecode(res.body)),
      );
    }
    setState(() => loading = false);
  }

  void answerFaq(int faqId) async {
    final ctrl = answerControllers[faqId];
    if (ctrl == null || ctrl.text.trim().isEmpty) return;
    await http.post(
      Uri.parse("$apiBase/faqs/answer/$faqId"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"answer": ctrl.text, "doctor_id": widget.doctor['id']}),
    );
    ctrl.clear();
    fetchFaqs();
  }

  // Assign pastel colors to FAQ cards in a cyclic fashion
  Color _cardAccent(int idx) {
    final accents = [
      kPastelBlue,
      kPastelPeach,
      kPastelGreen,
      kPastelLilac,
      kPastelYellow
    ];
    return accents[idx % accents.length].withOpacity(0.13);
  }

  Color _iconAccent(int idx) {
    final accents = [
      kPastelBlue,
      kPastelPeach,
      kPastelGreen,
      kPastelLilac,
      kPastelYellow
    ];
    return accents[idx % accents.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBG,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: loading
            ? Center(child: CircularProgressIndicator(color: kMutedDarkGreen))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FAQs",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: kMutedDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (_, __) => SizedBox(height: 12),
                      itemCount: faqs.length,
                      itemBuilder: (context, idx) {
                        final f = faqs[idx];
                        answerControllers.putIfAbsent(
                          f['id'],
                          () => TextEditingController(),
                        );
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          color: kCardBG,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _cardAccent(idx),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      padding: const EdgeInsets.all(7),
                                      child: Icon(Icons.help_outline,
                                          color: _iconAccent(idx), size: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        f['question'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: kMutedDarkGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (f['answer'] != null)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _cardAccent(idx),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: _iconAccent(idx), size: 19),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "A: ${f['answer']}",
                                                style: TextStyle(
                                                  color: kMutedDarkGreen,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if ((f['doctor_name'] ?? '')
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 2.0),
                                                  child: Text(
                                                    "By: ${f['doctor_name']}",
                                                    style: TextStyle(
                                                      color: kMutedDarkGreen
                                                          .withOpacity(0.7),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "No answer yet.",
                                        style: TextStyle(
                                          color:
                                              kMutedDarkGreen.withOpacity(0.45),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: answerControllers[f['id']],
                                        decoration: InputDecoration(
                                          labelText: "Your Answer",
                                          labelStyle: TextStyle(
                                              color: kMutedDarkGreen
                                                  .withOpacity(0.8)),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                                color: _iconAccent(idx)
                                                    .withOpacity(0.6)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                                color: _iconAccent(idx),
                                                width: 2),
                                          ),
                                          fillColor: _cardAccent(idx),
                                          filled: true,
                                        ),
                                        minLines: 1,
                                        maxLines: 2,
                                        style:
                                            TextStyle(color: kMutedDarkGreen),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => answerFaq(f['id']),
                                        icon: Icon(Icons.send,
                                            color: Colors.white),
                                        label: Text("Submit Answer"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _iconAccent(idx),
                                          foregroundColor: Colors.white,
                                          shape: StadiumBorder(),
                                        ),
                                      ),
                                    ],
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
