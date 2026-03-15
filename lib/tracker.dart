import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  // Controllers
  final TextEditingController _medicationTimeController =
      TextEditingController();
  final TextEditingController _wakeUpTimeController =
      TextEditingController();
  final TextEditingController _bedTimeController =
      TextEditingController();

  // Toggles
  bool _isMedicationTaken = false;
  bool _isMorningCheckIn = false;
  bool _isLoading = true;

  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _medicationTimeController.dispose();
    _wakeUpTimeController.dispose();
    _bedTimeController.dispose();
    super.dispose();
  }

  // ---------------- NOTIFICATIONS ----------------

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'routine_channel',
          channelName: 'Routine Notifications',
          channelDescription:
              'Reminders for wakeup, medication, and bedtime',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF4ADE80),
          ledColor: Colors.white,
        )
      ],
    );

    bool allowed =
        await AwesomeNotifications().isNotificationAllowed();

    if (!allowed) {
      await AwesomeNotifications()
          .requestPermissionToSendNotifications();
    }
  }

  void _scheduleNotification(
      String title, String time24h, int id) {
    if (time24h.isEmpty) return;

    final parts = time24h.split(':');
    if (parts.length != 2) return;

    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'routine_channel',
        title: '⏰ $title',
        body: "It's time for your $title",
        notificationLayout:
            NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }

  // ---------------- FIRESTORE ----------------

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc =
          await _firestore.collection('Users').doc(user!.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final today =
            DateFormat('yyyy-MM-dd').format(DateTime.now());

        setState(() {
          _medicationTimeController.text =
              data['medicationTime'] ?? '';
          _wakeUpTimeController.text =
              data['wakeUpTime'] ?? '';
          _bedTimeController.text =
              data['bedTime'] ?? '';

          if (data['lastUpdateDate'] == today) {
            _isMedicationTaken =
                data['isMedicationTaken'] ?? false;
            _isMorningCheckIn =
                data['isMorningCheckIn'] ?? false;
          }
        });
      }
    } catch (e) {
      debugPrint("Load error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTrackerStatus(
      String field, bool value) async {
    if (user == null) return;

    HapticFeedback.selectionClick();

    setState(() {
      if (field == 'isMedicationTaken') {
        _isMedicationTaken = value;
      }
      if (field == 'isMorningCheckIn') {
        _isMorningCheckIn = value;
      }
    });

    final today =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final userRef =
        _firestore.collection('Users').doc(user!.uid);

    try {
      await userRef.set({
        field: value,
        'lastUpdateDate': today,
      }, SetOptions(merge: true));

      if (field == 'isMedicationTaken') {
        final historyRef =
            userRef.collection('MedicationHistory').doc(today);

        if (value) {
          await historyRef.set({
            'status': 'taken',
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          await historyRef.delete();
        }
      }
    } catch (e) {
      debugPrint("Update failed: $e");
    }
  }

  Future<void> _saveSchedule() async {
    if (user == null) return;

    HapticFeedback.mediumImpact();

    try {
      await _firestore.collection('Users').doc(user!.uid).set({
        'medicationTime': _medicationTimeController.text,
        'wakeUpTime': _wakeUpTimeController.text,
        'bedTime': _bedTimeController.text,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Routine Updated Successfully!'),
            backgroundColor: const Color(0xFF064E3B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      _scheduleNotification(
          'Wake Up', _wakeUpTimeController.text, 100);
      _scheduleNotification(
          'Bedtime', _bedTimeController.text, 101);
      _scheduleNotification(
          'Medication Time',
          _medicationTimeController.text,
          102);
    } catch (e) {
      debugPrint("Save failed: $e");
    }
  }

  // ---------------- UI ----------------

  String _formatTimeDisplay(String time24h) {
    if (time24h.isEmpty) return "Set Time";

    try {
      final date =
          DateFormat("HH:mm").parse(time24h);
      return DateFormat("hh:mm a").format(date);
    } catch (_) {
      return time24h;
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress =
        (_isMedicationTaken ? 0.5 : 0.0) +
            (_isMorningCheckIn ? 0.5 : 0.0);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF020617),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4ADE80),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF064E3B),
              Color(0xFF020617),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildProgressIndicator(progress),
                const SizedBox(height: 30),
                _buildSectionTitle("Daily Reminders"),
                _buildTimeCard(
                    'Target Wake Up',
                    _wakeUpTimeController,
                    Icons.wb_sunny_outlined),
                _buildTimeCard(
                    'Target Bedtime',
                    _bedTimeController,
                    Icons.nights_stay_outlined),
                _buildTimeCard(
                    'Medication Time',
                    _medicationTimeController,
                    Icons.medication_outlined),
                const SizedBox(height: 16),
                _buildSaveButton(),
                const SizedBox(height: 40),
                _buildSectionTitle(
                    "Consistency (7 Days)"),
                _buildHistoryChart(),
                const SizedBox(height: 40),
                _buildSectionTitle(
                    "Today's Check-in"),
                _buildTrackerCard(
                  'Medication Logged',
                  _isMedicationTaken,
                  Icons.medication,
                  () => _saveTrackerStatus(
                      'isMedicationTaken',
                      !_isMedicationTaken),
                ),
                _buildTrackerCard(
                  'I am Awake & Grounded',
                  _isMorningCheckIn,
                  Icons.sunny,
                  () => _saveTrackerStatus(
                      'isMorningCheckIn',
                      !_isMorningCheckIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () =>
              Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
        ),
        const Text(
          "Wellness Tracker",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Completion",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontWeight:
                        FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: const Color(0xFF4ADE80),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4ADE80),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTimeCard(
      String label,
      TextEditingController controller,
      IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () async {
          TimeOfDay? picked =
              await showTimePicker(
            context: context,
            initialTime:
                TimeOfDay.now(),
          );

          if (picked != null) {
            setState(() {
              controller.text =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            });
          }
        },
        leading:
            Icon(icon, color: Colors.white54),
        title: Text(label,
            style: const TextStyle(
                color: Colors.white70)),
        trailing: Text(
          _formatTimeDisplay(controller.text),
          style: const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saveSchedule,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF4ADE80),
          foregroundColor:
              Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "SAVE ROUTINE",
          style: TextStyle(
              fontWeight:
                  FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildTrackerCard(
      String title,
      bool done,
      IconData icon,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done
              ? const Color(0xFF4ADE80)
                  .withOpacity(0.15)
              : Colors.white
                  .withOpacity(0.05),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: done
                    ? const Color(
                        0xFF4ADE80)
                    : Colors.white30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    color: done
                        ? Colors.white
                        : Colors.white60),
              ),
            ),
            Icon(
              done
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: done
                  ? const Color(0xFF4ADE80)
                  : Colors.white24,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryChart() {
    if (user == null) {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Users')
          .doc(user!.uid)
          .collection('MedicationHistory')
          .orderBy('timestamp',
              descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snapshot) {
        List<String> takenDays =
            snapshot.hasData
                ? snapshot.data!.docs
                    .map((d) => d.id)
                    .toList()
                : [];

        return Container(
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white
                .withOpacity(0.05),
            borderRadius:
                BorderRadius.circular(
                    24),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children:
                List.generate(7, (index) {
              DateTime day =
                  DateTime.now()
                      .subtract(
                Duration(
                    days:
                        6 - index),
              );

              bool didTake =
                  takenDays.contains(
                DateFormat(
                        'yyyy-MM-dd')
                    .format(day),
              );

              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration:
                        BoxDecoration(
                      color: didTake
                          ? const Color(
                              0xFF4ADE80)
                          : Colors.white10,
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      didTake
                          ? Icons.check
                          : Icons.close,
                      size: 18,
                      color: didTake
                          ? Colors.black
                          : Colors.white24,
                    ),
                  ),
                  const SizedBox(
                      height: 8),
                  Text(
                    DateFormat('E')
                        .format(day),
                    style: TextStyle(
                        color: didTake
                            ? Colors.white
                            : Colors
                                .white38,
                        fontSize: 10),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}