import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'doctor_profile_dialog.dart';
import 'doctor_patients_tab.dart';
import 'doctor_appointments_tab.dart';
import 'doctor_faq_tab.dart';
import 'doctor_articles_tab.dart';
import 'doctor_challenges_tab.dart';
import 'doctor_chat_tab.dart';

const String apiBase = "http://192.168.1.36:5000";

// --- App color scheme (matches login/register pages) ---
const Color kPastelBlue = Color(0xFF2CA7A3);
const Color kPastelGreen = Color(0xFF4B8246);
const Color kPastelPeach = Color(0xFFEB7B64);
const Color kPastelYellow = Color(0xFFD1AC00);
const Color kPastelLilac = Color(0xFF7A5FA0);
const Color kMutedDarkGreen = Color(0xFF297A6C);
const Color kBG = Colors.white;
const Color kCardBG = Color(0xFFF7F7F7);

class DoctorHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const DoctorHome({required this.user, Key? key}) : super(key: key);

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  Map<String, dynamic>? doctorProfile;
  bool loadingProfile = false;
  Map<String, dynamic>? selectedPatientForChat;

  // Notification Support
  List<Map<String, dynamic>> notifications = [];
  bool isNotifPanelOpen = false;
  bool hasNewNotification = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 6, vsync: this);
    fetchDoctorProfile();
    fetchNotifications();
    tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void fetchDoctorProfile() async {
    setState(() => loadingProfile = true);
    final res = await http.get(
      Uri.parse("$apiBase/doctor_profile/${widget.user['id']}"),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(
        () => doctorProfile = Map<String, dynamic>.from(jsonDecode(res.body)),
      );
    }
    setState(() => loadingProfile = false);
  }

  void fetchNotifications() async {
    final res = await http
        .get(Uri.parse("$apiBase/notifications/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      final nList = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      setState(() {
        notifications = nList;
        hasNewNotification =
            notifications.any((n) => n['read'] == 0 || n['read'] == false);
      });
    }
  }

  void markAllNotificationsRead() async {
    await http.put(
        Uri.parse("$apiBase/notifications/mark_read/${widget.user['id']}"));
    fetchNotifications();
  }

  void openNotificationsPanel() async {
    setState(() {
      isNotifPanelOpen = true;
    });
    markAllNotificationsRead();
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 420),
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications, color: kPastelLilac, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    "Notifications",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: kMutedDarkGreen),
                  ),
                  Spacer(),
                  IconButton(
                      icon: Icon(Icons.close, color: Colors.grey, size: 26),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Divider(),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Text(
                          "No notifications yet.",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final n = notifications[idx];
                          IconData notifIcon;
                          Color notifColor;
                          String type = n['type'] ?? '';
                          if (type == 'glucose') {
                            notifIcon = Icons.bloodtype;
                            notifColor = kPastelPeach;
                          } else if (type == 'message') {
                            notifIcon = Icons.chat_bubble_outline;
                            notifColor = kPastelBlue;
                          } else if (type == 'appointment') {
                            notifIcon = Icons.calendar_today_outlined;
                            notifColor = kPastelLilac;
                          } else {
                            notifIcon = Icons.notifications;
                            notifColor = kMutedDarkGreen;
                          }
                          String ts = n['created_at'] ?? '';
                          String formattedTs = ts.isNotEmpty
                              ? DateFormat('yyyy-MM-dd HH:mm').format(
                                  DateTime.tryParse(ts) ?? DateTime.now())
                              : '';
                          return ListTile(
                            leading: Icon(notifIcon, color: notifColor),
                            title: Text(n['title'] ?? '',
                                style: TextStyle(color: kMutedDarkGreen)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n['body'] ?? '',
                                    style: TextStyle(
                                        color:
                                            kMutedDarkGreen.withOpacity(0.8))),
                                if (formattedTs.isNotEmpty)
                                  Text(formattedTs,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                              ],
                            ),
                            trailing: n['read'] == 0 || n['read'] == false
                                ? Icon(Icons.circle,
                                    color: kPastelPeach, size: 12)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    setState(() {
      isNotifPanelOpen = false;
      hasNewNotification = false;
    });
  }

  void showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => DoctorProfileDialog(
        doctorProfile: doctorProfile,
        loading: loadingProfile,
        onRefresh: fetchDoctorProfile,
      ),
    );
  }

  void onPatientChatSelected(Map<String, dynamic> patient) {
    setState(() {
      selectedPatientForChat = patient;
      tabController.index = 5;
    });
  }

  Widget _tabButton(IconData icon, String label, int index) {
    final bool isSelected = tabController.index == index;
    // Assign a different pastel color to each tab
    final List<Color> tabColors = [
      kPastelBlue,
      kPastelGreen,
      kPastelPeach,
      kPastelLilac,
      kPastelYellow,
      kMutedDarkGreen,
    ];
    final bgColor =
        isSelected ? tabColors[index] : tabColors[index].withOpacity(0.10);
    final textColor = isSelected ? Colors.white : tabColors[index];
    final iconColor = isSelected ? Colors.white : tabColors[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton.icon(
        onPressed: () => setState(() => tabController.index = index),
        icon: Icon(icon, color: iconColor),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: kBG,
        foregroundColor: kMutedDarkGreen,
        title: Row(
          children: [
            Icon(Icons.medical_services, color: kMutedDarkGreen, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Welcome, ${widget.user['name']} (${widget.user['role']})",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kMutedDarkGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // NOTIFICATION BELL
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none,
                    color: kPastelLilac, size: 28),
                tooltip: 'Notifications',
                onPressed: () {
                  openNotificationsPanel();
                  fetchNotifications();
                },
              ),
              if (hasNewNotification)
                Positioned(
                  right: 10,
                  top: 12,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kPastelPeach,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: kPastelGreen,
              size: 30,
            ),
            tooltip: 'Profile',
            onPressed: showProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: kPastelPeach, size: 28),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabButton(Icons.people, "Patients", 0),
                _tabButton(Icons.schedule, "Appointments", 1),
                _tabButton(Icons.question_answer, "FAQ", 2),
                _tabButton(Icons.article, "Articles", 3),
                _tabButton(Icons.flag, "Challenges", 4),
                _tabButton(Icons.chat, "Chat", 5),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          DoctorPatientsTab(
            doctorId: widget.user['id'],
            onPatientChatSelected: onPatientChatSelected,
          ),
          DoctorAppointmentsTab(doctorId: widget.user['id']),
          DoctorFaqTab(doctor: widget.user),
          DoctorArticlesTab(user: widget.user),
          DoctorChallengesTab(doctor: widget.user),
          DoctorChatTab(
            doctor: widget.user,
            selectedPatient: selectedPatientForChat,
            onChatClosed: () => setState(() => selectedPatientForChat = null),
          ),
        ],
      ),
    );
  }
}
