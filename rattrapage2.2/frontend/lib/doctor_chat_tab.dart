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

class DoctorChatTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final Map<String, dynamic>? selectedPatient;
  final VoidCallback? onChatClosed;

  const DoctorChatTab({
    required this.doctor,
    required this.selectedPatient,
    this.onChatClosed,
  });

  @override
  State<DoctorChatTab> createState() => _DoctorChatTabState();
}

class _DoctorChatTabState extends State<DoctorChatTab> {
  List<Map<String, dynamic>> messages = [];
  final chatCtrl = TextEditingController();
  bool loadingMessages = false;

  @override
  void didUpdateWidget(covariant DoctorChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selected patient changes, reload chat
    if (widget.selectedPatient != oldWidget.selectedPatient) {
      fetchMessages();
    }
  }

  @override
  void dispose() {
    chatCtrl.dispose();
    super.dispose();
  }

  void fetchMessages() async {
    if (widget.selectedPatient == null) return;
    setState(() => loadingMessages = true);
    final res = await http.get(
      Uri.parse(
        "$apiBase/messages/${widget.doctor['id']}/${widget.selectedPatient!['id']}",
      ),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(
        () => messages = List<Map<String, dynamic>>.from(jsonDecode(res.body)),
      );
    }
    setState(() => loadingMessages = false);
  }

  void sendMessage() async {
    if (chatCtrl.text.isEmpty || widget.selectedPatient == null) return;
    await http.post(
      Uri.parse("$apiBase/messages"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "sender_id": widget.doctor['id'],
        "receiver_id": widget.selectedPatient!['id'],
        "message": chatCtrl.text,
      }),
    );
    chatCtrl.clear();
    fetchMessages();
  }

  // Assign pastel colors to patient avatars in a cyclic fashion
  Color _avatarBgColor(int idx) {
    final colors = [
      kPastelBlue,
      kPastelPeach,
      kPastelGreen,
      kPastelLilac,
      kPastelYellow,
    ];
    return colors[idx % colors.length].withOpacity(0.13);
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
    if (widget.selectedPatient == null) {
      return Container(
        color: kBG,
        child: Center(
          child: Text(
            "Select a patient from Patients tab to chat.",
            style: TextStyle(
              color: kMutedDarkGreen.withOpacity(0.36),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Container(
      color: kBG,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: kPastelGreen.withOpacity(0.17),
                  child: Icon(Icons.person, color: kPastelGreen, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Chat with ${widget.selectedPatient!['name']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: kMutedDarkGreen,
                    ),
                  ),
                ),
                if (widget.onChatClosed != null)
                  IconButton(
                    icon: Icon(Icons.close, color: kPastelPeach),
                    tooltip: "Close chat",
                    onPressed: widget.onChatClosed,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loadingMessages
                  ? Center(
                      child: CircularProgressIndicator(color: kMutedDarkGreen))
                  : ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, idx) {
                        final m = messages[messages.length - 1 - idx];
                        final isMe = m['sender_id'] == widget.doctor['id'];
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 6,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 15,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? kPastelBlue.withOpacity(0.14)
                                  : kCardBG,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isMe ? 16 : 6),
                                topRight: Radius.circular(isMe ? 6 : 16),
                                bottomLeft: const Radius.circular(13),
                                bottomRight: const Radius.circular(13),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kMutedDarkGreen.withOpacity(0.04),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              m['message'],
                              style: TextStyle(
                                fontSize: 15,
                                color: kMutedDarkGreen,
                                fontWeight:
                                    isMe ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatCtrl,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle:
                          TextStyle(color: kMutedDarkGreen.withOpacity(0.41)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: kMutedDarkGreen.withOpacity(0.13)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kPastelBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: kCardBG,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    style: TextStyle(color: kMutedDarkGreen),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPastelBlue,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
