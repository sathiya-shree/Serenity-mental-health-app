import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- THE COMPLETE LIST OF ALL TESTS WITH SCORING MARKS ---
  final List<Map<String, dynamic>> tests = [
    {
      'name': 'Depression', 
      'route': '/test/depression', 
      'icon': Icons.sentiment_very_dissatisfied, 
      'color': Colors.blueAccent,
      'desc': 'Measures persistent sadness, low energy, and loss of interest.',
      'how': 'Based on the PHQ-9 scale (Patient Health Questionnaire).',
      'scoring': [
        {'range': '0-4', 'label': 'Minimal Symptoms'},
        {'range': '5-9', 'label': 'Mild Depression'},
        {'range': '10-14', 'label': 'Moderate Depression'},
        {'range': '15-27', 'label': 'Severe Depression'},
      ]
    },
    {
      'name': 'Anxiety', 
      'route': '/test/anxiety', 
      'icon': Icons.psychology, 
      'color': Colors.orangeAccent,
      'desc': 'Screens for generalized anxiety and restlessness.',
      'how': 'Uses the GAD-7 tool to measure anxiety severity.',
      'scoring': [
        {'range': '0-4', 'label': 'Minimal Anxiety'},
        {'range': '5-9', 'label': 'Mild Anxiety'},
        {'range': '10-14', 'label': 'Moderate Anxiety'},
        {'range': '15-21', 'label': 'Severe Anxiety'},
      ]
    },
    {
      'name': 'Burnout', 
      'route': '/test/burnout', 
      'icon': Icons.battery_alert, 
      'color': Colors.deepOrangeAccent,
      'desc': 'Evaluates emotional exhaustion and work-life fatigue.',
      'how': 'Measures cynicism and sense of personal accomplishment.',
      'scoring': [
        {'range': 'Low', 'label': 'High Resilience'},
        {'range': 'Med', 'label': 'Risk of Burnout'},
        {'range': 'High', 'label': 'Severe Burnout'},
      ]
    },
    {
      'name': 'Stress', 
      'route': '/test/stress', 
      'icon': Icons.flash_on, 
      'color': Colors.redAccent,
      'desc': 'Assesses perception of life pressures and coping ability.',
      'how': 'Based on the Perceived Stress Scale (PSS).',
      'scoring': [
        {'range': '0-13', 'label': 'Low Stress'},
        {'range': '14-26', 'label': 'Moderate Stress'},
        {'range': '27-40', 'label': 'High Stress'},
      ]
    },
    {
      'name': 'ADHD', 
      'route': '/test/adhd', 
      'icon': Icons.bolt, 
      'color': Colors.indigoAccent,
      'desc': 'Checks for patterns of inattention and hyperactivity.',
      'how': 'Utilizes the ASRS clinical screening tool.',
      'scoring': [
        {'range': '0-3', 'label': 'Lower Likelihood'},
        {'range': '4-6', 'label': 'High Likelihood of ADHD'},
      ]
    },
    {
      'name': 'OCD', 
      'route': '/test/ocd', 
      'icon': Icons.loop, 
      'color': Colors.purpleAccent,
      'desc': 'Screens for intrusive thoughts and rituals.',
      'how': 'Measures time spent on rituals and associated distress.',
      'scoring': [
        {'range': '0-7', 'label': 'Subclinical'},
        {'range': '8-15', 'label': 'Mild OCD'},
        {'range': '16-23', 'label': 'Moderate OCD'},
        {'range': '24-40', 'label': 'Severe OCD'},
      ]
    },
    {
      'name': 'Bipolar', 
      'route': '/test/bipolar', 
      'icon': Icons.swap_horiz, 
      'color': Colors.tealAccent,
      'desc': 'Evaluates swings between mania and depression.',
      'how': 'Uses the Mood Disorder Questionnaire (MDQ).',
      'scoring': [
        {'range': 'Negative', 'label': 'Low Likelihood'},
        {'range': 'Positive', 'label': 'Clinical Review Needed'},
      ]
    },
    {
      'name': 'PTSD', 
      'route': '/test/ptsd', 
      'icon': Icons.warning_amber, 
      'color': Colors.brown,
      'desc': 'Screens for distress related to traumatic events.',
      'how': 'Based on the PCL-5 checklist for hyperarousal.',
      'scoring': [
        {'range': '0-30', 'label': 'Lower Severity'},
        {'range': '31-80', 'label': 'Probable PTSD'},
      ]
    },
    {
      'name': 'Eating Disorder', 
      'route': '/test/eating', 
      'icon': Icons.restaurant, 
      'color': Colors.greenAccent,
      'desc': 'Assesses relationship with food and body image.',
      'how': 'Uses the SCOFF screening tool for behaviors.',
      'scoring': [
        {'range': '0-1', 'label': 'Low Risk'},
        {'range': '2-5', 'label': 'Further Assessment Advised'},
      ]
    },
  ];

  bool _showEmergencyReferral = false;
  bool _showRetestNudge = false;
  bool _adaptiveShown = false;

  bool _isTestAvailable(Timestamp? lastTakenTimestamp) {
    if (lastTakenTimestamp == null) return true;
    return DateTime.now().difference(lastTakenTimestamp.toDate()).inHours >= 24;
  }

void _evaluateClinicalStatus(Map<String, dynamic> userData) {
  final lastTests = userData['lastTests'] ?? {};

  if (!lastTests.containsKey('Anxiety')) return;

  final anxietyData = lastTests['Anxiety'];

  final int lastScore = anxietyData['score'] ?? 0;
  final int streak = anxietyData['streak'] ?? 0;
  final Timestamp? lastTimestamp = anxietyData['timestamp'];

  if (lastTimestamp == null) return;

  bool passed24h =
      DateTime.now().difference(lastTimestamp.toDate()).inHours >= 24;

  Future.microtask(() {
    if (!mounted) return;

    setState(() {
      _showEmergencyReferral = streak >= 3;
      _showRetestNudge =
          !_showEmergencyReferral && passed24h && lastScore >= 15;
    });

    if (lastScore >= 15 &&
        !_adaptiveShown &&
        !_showEmergencyReferral) {
      _adaptiveShown = true;
      _showAdaptiveSupport(context);
    }
  });
}

  // --- THE EXPLANATION MODAL WITH SCORING MARKS ---
  void _showTestExplanation(BuildContext context, Map<String, dynamic> test) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 30),
          decoration: const BoxDecoration(
            color: Color(0xFF022C22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 45, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              Row(
                children: [
                  Icon(test['icon'], color: test['color'], size: 30),
                  const SizedBox(width: 15),
                  Text("${test['name']} Guide", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 25),
              _buildModalSection("CLINICAL OVERVIEW", test['desc']),
              const SizedBox(height: 20),
              _buildModalSection("METHODOLOGY", test['how']),
              const SizedBox(height: 25),
              const Text("SCORING MARKS", style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              
              // Scoring Legend Table
              Container(
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                child: Column(
                  children: (test['scoring'] as List).map((score) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(score['range'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(score['label'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: test['color'],
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text("CLOSE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF022C22), Color(0xFF020617)],
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('Users').doc(user?.uid).snapshots(),
          builder: (context, snapshot) {
            Map<String, dynamic> lastTests = {};
            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              lastTests = userData['lastTests'] ?? {};
              _evaluateClinicalStatus(userData);
            }

            return Stack(
              children: [
                _buildBackgroundGlow(),
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: SafeArea(child: _buildHeader(context))),
                    SliverToBoxAdapter(child: _buildHeroCard(context)),
                    SliverToBoxAdapter(child: _buildClinicalAlert()),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                        child: Text("Mental Wellness Checks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final test = tests[index];
                            final testData = lastTests[test['name']];
                            return _buildTestTile(context, test, testData?['timestamp']);
                          },
                          childCount: tests.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

 Widget _buildTestTile(
    BuildContext context,
    Map<String, dynamic> test,
    Timestamp? lastTimestamp,
) {
  bool isAvailable = _isTestAvailable(lastTimestamp);

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GestureDetector(
      onTap: isAvailable
          ? () {
              Navigator.of(context, rootNavigator: true)
                  .pushNamed(test['route']);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: (test['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                test['icon'],
                color: test['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isAvailable ? "Ready to take" : "Locked for 24hrs",
                    style: TextStyle(
                      color: isAvailable
                          ? const Color(0xFF4ADE80)
                          : Colors.white30,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () => _showTestExplanation(context, test),
            ),
            Icon(
              isAvailable
                  ? Icons.chevron_right_rounded
                  : Icons.lock_clock_outlined,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SERENITY", style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 4)),
                Text("Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
            child: const CircleAvatar(radius: 20, backgroundColor: Colors.white10, child: Icon(Icons.person_outline, color: Colors.white)),
          ),
        ],
      ),
    );
  }

 Widget _buildHeroCard(BuildContext context) {
  return GestureDetector(
    onTap: () => _showAssessmentInfo(context),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TRACK YOUR GROWTH", 
                  style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text("Clinical Tools", 
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // Explicit disclaimer text
                Text("Self-assessments only. Not a clinical diagnosis.", 
                  style: TextStyle(color: Colors.orangeAccent.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Stacked Icon: Sparkle with a Warning overlay
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80), 
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.black, size: 24),
              ),
              // THE WARNING OVERLAY
              Transform.translate(
                offset: const Offset(4, -4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.priority_high_rounded, color: Colors.black, size: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildClinicalAlert() {
    if (!_showEmergencyReferral && !_showRetestNudge) return const SizedBox.shrink();
    final isEmergency = _showEmergencyReferral;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.redAccent.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isEmergency ? Colors.redAccent.withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isEmergency ? Icons.healing_rounded : Icons.history_rounded, color: isEmergency ? Colors.redAccent : Colors.orangeAccent),
              const SizedBox(width: 12),
              Text(isEmergency ? "Support Recommended" : "Time for Check-in", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(isEmergency ? "High scores for 4 days. Please talk to a professional." : "24 hours since your last check-in. Let's see how you feel.", style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // Same logic as before for general info
  void _showAssessmentInfo(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(color: Color(0xFF064E3B), borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF4ADE80), size: 40),
            const SizedBox(height: 20),
            const Text("Self-Assessment Guide", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text("Results are NOT a medical diagnosis. Please consult a doctor for clinical advice.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("OK", style: TextStyle(color: Colors.black))),
          ],
        ),
      ),
    );
  }
  void _showAdaptiveSupport(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF022C22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite,
                color: Color(0xFF4ADE80), size: 40),
            const SizedBox(height: 20),

            const Text(
              "Immediate Support Available",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              "Your recent assessment shows elevated emotional distress.\n"
              "Would you like to try a quick support tool?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/GroundingExerciseScreen');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Try SOS Calm",
                  style: TextStyle(color: Colors.black)),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/DiaryEntryScreen');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Open Journal",
                  style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ChatPage');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Talk to Support Bot",
                  style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),

            const Text(
              "This is supportive guidance and not a medical diagnosis.",
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: 150, left: -100,
      child: Container(
        width: 350, height: 350,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4ADE80).withOpacity(0.04)),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
      ),
    );
  }
}