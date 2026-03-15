import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final String _yesterday =
      DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

  bool _isLoading = true;
  double _yesterdayProgress = 0.0;
  final List<double> _weeklyPercentages = [0, 0, 0, 0, 0, 0, 0];

  final List<Map<String, dynamic>> _habits = [
    {'id': 'water', 'title': 'Hydrate (1L)', 'icon': Icons.water_drop, 'done': false, 'color': Colors.blueAccent, 'streak': 0},
    {'id': 'sun', 'title': '5 mins Sunlight', 'icon': Icons.wb_sunny, 'done': false, 'color': Colors.orangeAccent, 'streak': 0},
    {'id': 'noscreen', 'title': 'No Screen (First 15m)', 'icon': Icons.phonelink_off, 'done': false, 'color': Colors.redAccent, 'streak': 0},
    {'id': 'gratitude', 'title': 'One Thing I\'m Grateful For', 'icon': Icons.auto_awesome, 'done': false, 'color': Colors.amberAccent, 'streak': 0},
    {'id': 'breath', 'title': 'Deep Breathing', 'icon': Icons.air, 'done': false, 'color': Colors.cyanAccent, 'streak': 0},
    {'id': 'make_bed', 'title': 'Make the Bed', 'icon': Icons.king_bed, 'done': false, 'color': Colors.brown, 'streak': 0},
    {'id': 'mood', 'title': 'Mood Check-in', 'icon': Icons.psychology, 'done': false, 'color': Colors.purpleAccent, 'streak': 0},
    {'id': 'stretch', 'title': 'Body Movement', 'icon': Icons.accessibility_new, 'done': false, 'color': Colors.greenAccent, 'streak': 0},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeNotifications();
  }

  // --- AWESOME NOTIFICATIONS ---
  void _initializeNotifications() async {
    // Initialize notifications
    AwesomeNotifications().initialize(
      null, // app icon, null uses default
      [
        NotificationChannel(
          channelKey: 'habit_channel',
          channelName: 'Habit Notifications',
          channelDescription: 'Daily reminders for your habits',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF4ADE80),
          ledColor: Colors.white,
        ),
      ],
    );

    // Request permission if not granted
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Schedule daily notification at 8 AM
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'habit_channel',
        title: '🌟 Time for your habits!',
        body: 'Don’t forget to complete your daily habits today.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 8,
        minute: 0,
        second: 0,
        repeats: true,
      ),
    );
  }

  Future<void> _initializeData() async {
    await _loadHabitsAndStreaks();
    await _loadWeeklyHistory();
    if (mounted) setState(() => _isLoading = false);
  }

  // --- ENCOURAGEMENT LOGIC ---
  String _getEncouragementMessage() {
    double p = _progress;
    if (p == 0) return "Be gentle with yourself today. What's one tiny win we can start with?";
    if (p < 0.3) return "A beautiful start. Every small step is a victory for your mind.";
    if (p < 0.6) return "You're finding your rhythm. Doing even a little is better than nothing!";
    if (p < 1.0) return "So close! You've prioritized your well-being today, and that matters.";
    return "Incredible! You showed up for yourself 100% today. ✨";
  }

  // --- FIREBASE LOGIC ---
  Future<void> _loadHabitsAndStreaks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final todayDoc = await userDoc.collection('DailyHabits').doc(_today).get();
    final yesterdayDoc = await userDoc.collection('DailyHabits').doc(_yesterday).get();
    final streakDoc = await userDoc.collection('HabitStats').doc('streaks').get();

    setState(() {
      if (todayDoc.exists) {
        final data = todayDoc.data() as Map<String, dynamic>;
        for (var habit in _habits) {
          habit['done'] = data[habit['id']] ?? false;
        }
      }

      if (yesterdayDoc.exists) {
        final yData = yesterdayDoc.data() as Map<String, dynamic>;
        int completed = yData.values.where((v) => v == true).length;
        _yesterdayProgress = completed / _habits.length;
      }

      if (streakDoc.exists) {
        final sData = streakDoc.data() as Map<String, dynamic>;
        for (var habit in _habits) {
          habit['streak'] = sData[habit['id']] ?? 0;
        }
      }
    });
  }

  Future<void> _loadWeeklyHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (int i = 0; i < 7; i++) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      int weekdayIndex = date.weekday - 1;

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('DailyHabits')
          .doc(dateStr)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        int completedCount = data.values.where((v) => v == true).length;
        setState(() {
          _weeklyPercentages[weekdayIndex] = completedCount / _habits.length;
        });
      }
    }
  }

Future<void> _toggleHabit(int index) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  HapticFeedback.mediumImpact();

  setState(() {
    _habits[index]['done'] = !_habits[index]['done'];
    int todayIndex = DateTime.now().weekday - 1;
    _weeklyPercentages[todayIndex] = _habits.where((h) => h['done']).length / _habits.length;
  });

  final userDoc = FirebaseFirestore.instance.collection('Users').doc(user.uid);
  final String habitId = _habits[index]['id'];
  final String habitTitle = _habits[index]['title'];
  final bool isNowDone = _habits[index]['done'];

  try {
    final batch = FirebaseFirestore.instance.batch();

    if (isNowDone) {
      DocumentReference historyRef = FirebaseFirestore.instance.collection('habits').doc();
      batch.set(historyRef, {
        'userId': user.uid,
        'habitType': habitTitle,
        'habitId': habitId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // --- FIX 1: Explicitly cast the DailyHabits map ---
    final Map<String, dynamic> dailyData = Map<String, dynamic>.from({
      for (var h in _habits) h['id'].toString(): h['done']
    });
    batch.set(userDoc.collection('DailyHabits').doc(_today), dailyData);

    if (isNowDone) {
      _habits[index]['streak'] += 1;
    } else {
      _habits[index]['streak'] = (_habits[index]['streak'] > 0) ? _habits[index]['streak'] - 1 : 0;
    }

    // --- FIX 2: Explicitly cast the streaks map ---
    final Map<String, dynamic> streakData = Map<String, dynamic>.from({
      for (var h in _habits) h['id'].toString(): h['streak']
    });
    batch.set(userDoc.collection('HabitStats').doc('streaks'), streakData, SetOptions(merge: true));

    // --- FIX 3: Last activity update ---
    batch.set(userDoc, {
      'lastHabitCompleted': habitTitle,
      'lastHabitTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  } catch (e) {
    debugPrint('Error syncing habit: $e');
    if (mounted) {
      setState(() {
        _habits[index]['done'] = !isNowDone;
      });
    }
  }
}
  

  double get _progress => _habits.where((h) => h['done']).length / _habits.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text(
          "HABIT LANE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, letterSpacing: 3),
        ),
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProgressHeader(),
                  _buildComparisonCard(),
                  _buildWeeklyVisualizer(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _habits.length,
                    itemBuilder: (context, index) => _buildHabitCard(index),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF064E3B),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Text("${(_progress * 100).toInt()}% Done Today",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              color: const Color(0xFF4ADE80),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_twilight_rounded, color: Color(0xFF4ADE80), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getEncouragementMessage(),
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    bool improved = _progress >= _yesterdayProgress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("YESTERDAY", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                Text("${(_yesterdayProgress * 100).toInt()}% completed",
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            Icon(
              improved ? Icons.keyboard_double_arrow_up_rounded : Icons.trending_flat,
              color: improved ? const Color(0xFF4ADE80) : Colors.orangeAccent,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyVisualizer() {
    List<String> weekDays = ["M", "T", "W", "T", "F", "S", "S"];
    int todayIndex = DateTime.now().weekday - 1;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          bool isToday = index == todayIndex;
          return Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(height: 50, width: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 50 * _weeklyPercentages[index],
                    width: 8,
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF4ADE80) : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(weekDays[index], style: TextStyle(color: isToday ? Colors.white : Colors.white38, fontSize: 10)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHabitCard(int index) {
    final habit = _habits[index];
    bool isDone = habit['done'];

    return GestureDetector(
      onTap: () => _toggleHabit(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFF4ADE80).withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDone ? const Color(0xFF4ADE80).withOpacity(0.5) : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(habit['icon'], color: isDone ? const Color(0xFF4ADE80) : habit['color'], size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  if (habit['streak'] > 0)
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 4),
                        Text("${habit['streak']} day streak", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),
            Icon(isDone ? Icons.check_circle : Icons.circle_outlined, color: isDone ? const Color(0xFF4ADE80) : Colors.white24),
          ],
        ),
      ),
    );
  }
}
