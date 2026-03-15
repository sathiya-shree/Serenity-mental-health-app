
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:niramaya/grounding_exercise_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';


import 'login.dart';
import 'chat.dart';
import 'diary_entry.dart';
import 'daily_wins.dart';
import 'home.dart';
import 'helpline.dart';
import 'profile.dart';
import 'tracker.dart';
import 'youtube.dart';
import 'perspective_shift.dart';
import 'zen_player.dart';
import 'help_page.dart';
import 'gratitude_jar_view.dart';


class ContainerScreen extends StatefulWidget {
  const ContainerScreen({super.key});

  @override
  State<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends State<ContainerScreen> with TickerProviderStateMixin {
  
  Color _moodColorStart = const Color(0xFF064E3B);
  final Color _moodColorEnd = const Color(0xFF020617);
  bool _isSyncing = true;
  String _currentMoodEmoji = "🧘";
  int wellnessStreak = 0;
  List<String> _weeklyMoods = ["-", "-", "-", "-", "-", "-", "-"];
  int _weeklyProgress = 0;

  final Map<String, String> emotionalReflections = {
  "angry": "Anger usually protects something softer underneath.",
  "sad": "Sadness often means something mattered deeply.",
  "anxious": "Anxiety is your mind trying to protect you.",
  "tired": "Exhaustion is a sign you’ve been strong for too long.",
  "overwhelmed": "When everything feels too much, it’s okay to pause.",
  "numb": "Numbness can be your system asking for safety.",
  "jealous": "Jealousy can reveal what you truly desire.",
  "guilty": "Guilt can mean your values matter to you.",
};



  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }
  final List<Map<String, dynamic>> pickOfDay = [
    
  {
    "title": "Wind Downs", 
    "icon": Icons.nights_stay, 
    "sub": "Ethereal Ocean", 
    "url": "https://cdn.bensound.com/bensound-silentwaves.mp3"
  },
   {
  "title": "Daily Zen",
  "icon": Icons.self_improvement,
  "sub": "Inner Peace Meditation",
  "url": "https://cdn.bensound.com/bensound-relaxing.mp3"
},
  {
  "title": "Emotional Mirror",
  "icon": Icons.psychology,
  "sub": "Name it. See it differently.",
  "isEmotionalMirror": true,
},
{
  "title": "Memory Jar",
  "icon": Icons.auto_awesome,
  "sub": "Collect Happy Moments",
  "isJar": true,
},

  ];

  

@override
  void initState() {
    super.initState();
  

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _loadData().then((_) {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBreathingDialog(positiveMessage: "Breathe in peace, breathe out stress.");
    });
  }

  int _getIsoWeekNumber(DateTime date) {
    int daysAdded = DateTime.thursday - date.weekday;
    DateTime thursday = daysAdded > 0 ? date.add(Duration(days: daysAdded)) : date.subtract(Duration(days: -daysAdded));
    DateTime firstDayOfYear = DateTime(thursday.year, 1, 1);
    return ((thursday.difference(firstDayOfYear).inDays) / 7).floor() + 1;
  }

Future<void> _loadData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final prefs = await SharedPreferences.getInstance();

  final snapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(user.uid)
      .collection('WeeklyMoods')
      .get();

  int totalPeaceDays = 0;
  List<String> latestWeekMoods = ["-", "-", "-", "-", "-", "-", "-"];
  DateTime now = DateTime.now();
  int currentWeek = _getIsoWeekNumber(now);

  for (var doc in snapshot.docs) {
    Map<String, dynamic> data = doc.data();
    for (int i = 0; i < 7; i++) {
      if (data.containsKey('day_$i') && data['day_$i'] != "-") {
        totalPeaceDays++;
        if (doc.id.endsWith("_W$currentWeek")) {
          latestWeekMoods[i] = data['day_$i'];
        }
      }
    }
  }

  setState(() {
    wellnessStreak = totalPeaceDays; // Lifetime
    _weeklyMoods = latestWeekMoods;  // This week
    _weeklyProgress = latestWeekMoods.where((m) => m != "-").length;
    int todayIdx = now.weekday - 1;
    if (_weeklyMoods[todayIdx] != "-") _currentMoodEmoji = _weeklyMoods[todayIdx];
  });

  await prefs.setStringList('moodHistory_${user.uid}', latestWeekMoods);
}

void _updateMoodUI(String emoji) async {
  HapticFeedback.mediumImpact();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final prefs = await SharedPreferences.getInstance();

  final String today = DateTime.now().toIso8601String().substring(0, 10);
  final String lastDateKey = "lastMoodDate_${user.uid}";
  final String lifetimeKey = "lifetimePeaceDays_${user.uid}";


  int currentLifetime = prefs.getInt(lifetimeKey) ?? wellnessStreak;
 
  if (prefs.getString(lastDateKey) != today) {
    currentLifetime += 1;
    await prefs.setString(lastDateKey, today);
    await prefs.setInt(lifetimeKey, currentLifetime);
  }

  int dayIndex = DateTime.now().weekday - 1;

  setState(() {
    wellnessStreak = currentLifetime; 
    
    _currentMoodEmoji = emoji;
    _weeklyMoods[dayIndex] = emoji;
    _weeklyProgress = _weeklyMoods.where((m) => m != "-").length;


    switch (emoji) {
      case "😄": _moodColorStart = const Color(0xFF065F46); break;
      case "🙂": _moodColorStart = const Color(0xFF0D9488); break;
      case "😐": _moodColorStart = const Color(0xFF334155); break;
      case "😔": _moodColorStart = const Color(0xFF1E3A8A); break;
      case "😢": _moodColorStart = const Color(0xFF450A0A); break;
      case "😰": _moodColorStart = const Color(0xFF7C2D12); break;
      case "😴": _moodColorStart = const Color(0xFF4C1D95); break;
      default: _moodColorStart = const Color(0xFF064E3B);
    }
  });

  await prefs.setStringList('moodHistory_${user.uid}', _weeklyMoods);
  try {
    DateTime now = DateTime.now();
    String weekId = "${now.year}_W${_getIsoWeekNumber(now)}";
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('WeeklyMoods')
        .doc(weekId)
        .set({
      'day_$dayIndex': emoji,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint("Failed to save mood to cloud: $e");
  }

  Future.delayed(const Duration(milliseconds: 600), () {
    if (!mounted) return;
    switch (emoji) {
      case "😄": _showJarDialog(); break;
      case "🙂": _go(const DiaryEntryScreen()); break;
      case "😐": 
  _showWorryBox();
  break;
      case "🤔": _go(const PerspectiveShiftScreen()); break;
      case "😔": _go(const ChatPage()); break;
      case "😢": _go(const GroundingExerciseScreen()); break;
      case "😰": _go(const HomeScreen()); break;
      case "😴":
  _go(const ZenPlayer(
    title: "Deep Sleep",
    sub: "Restful Waves",
    icon: Icons.bedtime,
    audioUrl: "https://cdn.bensound.com/bensound-silentwaves.mp3",
  ));
  break;

    }
  });
}

  void _showJarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF064E3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Radiant Energy!", 
          style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
        content: const Text(
          "Since you're feeling great, would you like to add a new memory to your Jar?", 
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Later", style: TextStyle(color: Colors.white38))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80)),
            onPressed: () {
              Navigator.pop(context); 
              _showQuickAddMemory();  
            },
            child: const Text("Let's do it", style: TextStyle(color: Color(0xFF064E3B))),
          ),
        ],
      ),
    );
  }

  void _showQuickAddMemory() {
    final TextEditingController memoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF064E3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Add to your Jar", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: memoryController,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "What made you smile today?",
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: BorderSide.none
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80)),
            onPressed: () async {
              String memoryText = memoryController.text.trim();

              if (memoryText.isNotEmpty) {
                Navigator.pop(context); 

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(user.uid)
                        .collection('GratitudeJar')
                        .add({
                      'memory': memoryText,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✨ Memory tucked away in your jar!"),
                          backgroundColor: Color(0xFF065F46),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error: $e");
                  }
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Color(0xFF064E3B))),
          ),
        ],
      ),
    );
  }
  void _go(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> signOutUser() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _showBreathingDialog({String? positiveMessage}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BreathingCircle(),
              const SizedBox(height: 24),
              Text(
                positiveMessage ?? "Let's take a moment to breathe...",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("I'm ready", style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorryBox() {
    TextEditingController worryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("The Worry Box", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Write down what's heavy on your mind. We will hold it for you.",
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: worryController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "I am worried about...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Worry locked away. Let it go for now."), backgroundColor: Color(0xFF064E3B))
              );
            },
            child: const Text("Lock Away", style: TextStyle(color: Color(0xFF064E3B))),
          ),
        ],
      ),
    );
  }

void _showEmotionalMirror() {
  TextEditingController controller = TextEditingController();
  String? reflection;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: const Text(
              "Emotional Mirror 🪞",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Type what you're feeling in one word.",
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "e.g. angry,sad,numb,anxious,tired,overwhelmed,jealous,guilty",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                  ),
                  onPressed: () {
                    String input =
                        controller.text.trim().toLowerCase();
                    setState(() {
                      reflection =
                          emotionalReflections[input] ??
                              "That feeling deserves kindness too.";
                    });
                  },
                  child: const Text(
                    "Reflect",
                    style: TextStyle(color: Color(0xFF064E3B)),
                  ),
                ),
                if (reflection != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    reflection!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white38),
                ),
              )
            ],
          );
        },
      );
    },
  );
}

@override
Widget build(BuildContext context) {
  return ShowCaseWidget(
    builder: (context) => Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
  HapticFeedback.heavyImpact();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const GroundingExerciseScreen(),
    ),
  );
},

        backgroundColor: Colors.redAccent.withOpacity(0.9),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text(
          "SOS CALM",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_moodColorStart, _moodColorEnd],
          ),
        ),
        child: Stack(
          children: [
            _buildAmbientDecor(),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 20),
                    _buildQuickProfileCard(),
                    const SizedBox(height: 24),
                    _buildGrowthGarden(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Weekly Mood Summary"),
                    _buildMoodCalendar(),
                    const SizedBox(height: 24),
                    _buildMoodSelector(),
                    const SizedBox(height: 32),
                    _buildSectionTitle("Pick of the Day"),
                    _buildPickOfDayCarousel(),
                    const SizedBox(height: 32),
                    _buildSectionTitle("Healing Tools"),
                    _buildFeatureGrid(),
                    const SizedBox(height: 100),
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


  Widget _buildTopBar() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        "Serenity",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded,
                color: Colors.white70),
            onPressed: () => _go(const HelpPage()),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: Colors.white70),
            onPressed: signOutUser,
          ),
        ],
      ),
    ],
  );
}
Widget _glassBox({required Widget child, double radius = 28}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
Widget _buildQuickProfileCard() {
    final user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        String displayName = "Mindful User";
        String initials = "U";
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          displayName = userData['firstName']?.trim() ?? "Mindful User";
          initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact(); // Micro-interaction
            _go(const ProfilePage());
          },
          child: _glassBox( // Applying Glassmorphism
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withOpacity(0.3), blurRadius: 15)],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF4ADE80),
                      child: Text(initials, style: const TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(), style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5)),
                        Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// --- GROWTH GARDEN WIDGET ---
Widget _buildGrowthGarden(BuildContext context) {
  IconData stageIcon;
  String stageName;
  Color stageColor;

  // Evolution logic based on the wellnessStreak
  if (wellnessStreak >= 30) {
    stageIcon = Icons.forest_rounded;
    stageName = "Serene Forest";
    stageColor = const Color(0xFF4ADE80);
  } else if (wellnessStreak >= 14) {
    stageIcon = Icons.local_florist_rounded;
    stageName = "Blooming Garden";
    stageColor = Colors.orangeAccent;
  } else if (wellnessStreak >= 7) {
    stageIcon = Icons.park_rounded;
    stageName = "Young Tree";
    stageColor = Colors.lightGreenAccent;
  } else if (wellnessStreak >= 3) {
    stageIcon = Icons.spa_rounded;
    stageName = "Sprout";
    stageColor = Colors.greenAccent;
  } else {
    stageIcon = Icons.eco_outlined;
    stageName = "Seedling";
    stageColor = Colors.brown[300]!;
  }

return Container(
  width: double.infinity,
  padding: const EdgeInsets.all(24),
  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.03),
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: Colors.white.withOpacity(0.05)),
  ),
  child: Column( // <--- 1. ADD THIS LINE
    children: [  // <--- 2. ADD THIS LINE
      GestureDetector(
        onTap: () => _showGardenLegacy(context),
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF4ADE80), size: 22),
            const SizedBox(width: 8),
            Flexible( // <--- 3. THIS FIXES THE YELLOW OVERFLOW
              child: Text(
                "Your garden grows with every daily check-in.",
                textAlign: TextAlign.center, 
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 20),

      TweenAnimationBuilder(
        duration: const Duration(seconds: 2),
        tween: Tween<double>(begin: 0, end: 1),
        curve: Curves.elasticOut,
        builder: (context, double val, child) {
          return Transform.scale(
            scale: val * (1.0 + (wellnessStreak.clamp(0, 30) * 0.015)),
            child: Icon(stageIcon, color: stageColor, size: 70),
          );
        },
      ),
      
      const SizedBox(height: 15),
      
      Text(
        "$wellnessStreak Days of Peace", 
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
      ),
      
      const SizedBox(height: 6),
      
      Text(
        "This week: $_weeklyProgress / 7 check-ins",
        style: const TextStyle(color: Colors.white60, fontSize: 13),
      ),
      
      const SizedBox(height: 4),
      
      Text(
        stageName.toUpperCase(), 
        style: TextStyle(
          color: stageColor.withOpacity(0.8), 
          fontSize: 11, 
          letterSpacing: 2, 
          fontWeight: FontWeight.w900
        )
      ),
    ], // <--- 4. CLOSE THE CHILDREN LIST
  ),   // <--- 5. CLOSE THE COLUMN
);     // <--- 6. CLOSE THE CONTAINER
}

void _showGardenLegacy(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Dismiss",
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Dark slate theme
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Growth Roadmap",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Roadmap milestones
                _legendItem(Icons.forest_rounded, 30, "Serene Forest", const Color(0xFF4ADE80)),
                _legendDivider(30),
                _legendItem(Icons.local_florist_rounded, 14, "Blooming Garden", Colors.orangeAccent),
                _legendDivider(14),
                _legendItem(Icons.park_rounded, 7, "Young Tree", Colors.lightGreenAccent),
                _legendDivider(7),
                _legendItem(Icons.spa_rounded, 3, "Sprout", Colors.greenAccent),
                _legendDivider(3),
                _legendItem(Icons.eco_outlined, 0, "Seedling", Colors.brown[300]!),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.white54)),
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Helper: Individual Milestone Row
Widget _legendItem(IconData icon, int daysRequired, String name, Color color) {
  bool isReached = wellnessStreak >= daysRequired;
  
  return Row(
    children: [
      Icon(icon, color: isReached ? color : Colors.white10, size: 24),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name, 
            style: TextStyle(
              color: isReached ? Colors.white : Colors.white24, 
              fontWeight: FontWeight.bold,
              fontSize: 14
            )
          ),
          Text(
            daysRequired == 0 ? "Start your journey" : "$daysRequired Day Streak", 
            style: const TextStyle(color: Colors.white38, fontSize: 11)
          ),
        ],
      ),
      const Spacer(),
      if (isReached) 
        const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 16),
    ],
  );
}

// Helper: Vertical connecting line between icons
Widget _legendDivider(int threshold) {
  bool isReached = wellnessStreak >= threshold;
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      height: 12,
      width: 2,
      decoration: BoxDecoration(
        color: isReached ? const Color(0xFF4ADE80).withOpacity(0.3) : Colors.white10,
        borderRadius: BorderRadius.circular(1),
      ),
    ),
  );
}
  Widget _buildMoodCalendar() {
    List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
    int todayIndex = DateTime.now().weekday - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          bool isToday = index == todayIndex;
          return Column(
            children: [
              Text(days[index], style: TextStyle(color: isToday ? const Color(0xFF4ADE80) : Colors.white38, fontSize: 10, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
              const SizedBox(height: 8),
              Container(
                width: 35, height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF4ADE80).withOpacity(0.2) : Colors.white.withOpacity(0.05), 
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: const Color(0xFF4ADE80), width: 1) : null,
                ),
                child: Text(_weeklyMoods[index], style: const TextStyle(fontSize: 16)),
              ),
            ],
          );
        }),
      ),
    );
  }


  Widget _buildPickOfDayCarousel() {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pickOfDay.length,
        itemBuilder: (context, index) {
          final item = pickOfDay[index];
          return GestureDetector(
            onTap: () {
  HapticFeedback.mediumImpact();

  if (item["isJar"] == true) {
    _go(const GratitudeJarView());

  } else if (item["isEmotionalMirror"] == true) {
    _showEmotionalMirror();

  } else if (item['title'] == "Mindful Minute") {
    _showBreathingDialog(
      positiveMessage: "Reset your focus."
    );

  } else {
    _go(ZenPlayer(
      title: item['title'],
      sub: item['sub'],
      icon: item['icon'],
      audioUrl: item['url'],
    ));
  }
},
            child: Container(
              width: 200, margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], color: const Color(0xFF4ADE80), size: 28),
                  const SizedBox(height: 12),
                  Text(item['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(item['sub'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

Widget _buildMoodSelector() {
  final List<Map<String, String>> moods = [
    {"emoji": "😄", "label": "Happy"},
    {"emoji": "🙂", "label": "Calm"},
    {"emoji": "😐", "label": "Okay"},
    {"emoji": "🤔", "label": "Confused"},
    {"emoji": "😔", "label": "Sad"},
    {"emoji": "😰", "label": "Anxious"},
    {"emoji": "😢", "label": "Low"},
    {"emoji": "😴", "label": "Tired"},
  ];

  return SizedBox(
    height: 110,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: moods.length, // ✅ FIXED
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final mood = moods[index]; // ✅ FIXED
        final emoji = mood["emoji"]!;
        final label = mood["label"]!;
        final isSelected = _currentMoodEmoji == emoji;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _updateMoodUI(emoji);
          },
          child: AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(
                          isSelected ? 0.9 : 0.6),
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  
}

 Widget _buildFeatureGrid() {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 1.1,
    children: [
      // FIXED: Corrected the Mindful Minute syntax
      _featureCard(
        "Mindful Minute", 
        Icons.timer_outlined, 
        () => _showBreathingDialog(positiveMessage: "Focus on the circle. Inhale peace.")
      ),
        _featureCard("Dawn AI", Icons.auto_awesome, () => _go(const ChatPage())),
        _featureCard("Worry Box", Icons.all_inbox_rounded, () => _showWorryBox()),
        _featureCard("Journal", Icons.history_edu, () => _go(const DiaryEntryScreen())),
        _featureCard("Thought Flip", Icons.flip_to_back_rounded, () => _go(const PerspectiveShiftScreen())),
        _featureCard("Self Assessment", Icons.auto_awesome, () => _go(const HomeScreen())),
        _featureCard("Daily Wins", Icons.check_circle_outline, () => _go(const HabitTrackerScreen())),        
_featureCard(
  "Health Log", // Updated Name
  Icons.medication_liquid, // Updated Icon (Cross/Bottle style)
  () => _go(const TrackerPage())
),        _featureCard("Zen Library", Icons.self_improvement, () => _go(const YouTubeScreen())),        _featureCard("Talk to Someone", Icons.support_agent, () => _go(const Helpline())),
      ],
    );
  }

 Widget _featureCard(String title, IconData icon, VoidCallback onTap) {
    return _glassBox(
      radius: 24,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact(); // Micro-interaction
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: const Color(0xFF4ADE80)),
            ),
            const SizedBox(height: 12),
            Text(
              title, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _buildAmbientDecor() => Positioned(
    top: -100, right: -100,
    child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4ADE80).withOpacity(0.05)),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))),
  );
}

class BreathingCircle extends StatefulWidget {
  const BreathingCircle({super.key});
  @override State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: 120 + (60 * _controller.value),
        height: 120 + (60 * _controller.value),
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4ADE80).withOpacity(0.2), border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.4), width: 2)),
        child: Center(child: Text(_controller.status == AnimationStatus.forward ? "Inhale" : "Exhale", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ),
    );
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

}
