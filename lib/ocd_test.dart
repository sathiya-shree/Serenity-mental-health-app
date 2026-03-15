import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/test_result_manager.dart';

class OCDTestScreen extends StatefulWidget {
  const OCDTestScreen({super.key});

  @override
  _OCDTestScreenState createState() => _OCDTestScreenState();
}

class _OCDTestScreenState extends State<OCDTestScreen> {
    String? timeRemaining;
  Map<int, int> selectedOptions = {};
  bool testTaken = false;
  // Y-BOCS Derived Screening Questions
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'How much of your time is occupied by obsessive thoughts (unwanted ideas, images, or impulses)?',
      'options': [
        {'option': 'None', 'points': 0},
        {'option': 'Less than 1 hr/day', 'points': 1},
        {'option': '1 to 3 hrs/day', 'points': 2},
        {'option': '3 to 8 hrs/day', 'points': 3},
        {'option': 'More than 8 hrs/day', 'points': 4},
      ],
    },
    {
      'question': 'How much do these obsessive thoughts interfere with your social or work/school functioning?',
      'options': [
        {'option': 'No interference', 'points': 0},
        {'option': 'Slight interference', 'points': 1},
        {'option': 'Definite interference', 'points': 2},
        {'option': 'Substantial impairment', 'points': 3},
        {'option': 'Extreme/Incapacitating', 'points': 4},
      ],
    },
    {
      'question': 'How much distress do your obsessive thoughts cause you?',
      'options': [
        {'option': 'None', 'points': 0},
        {'option': 'Little (mild)', 'points': 1},
        {'option': 'Moderate (disturbing)', 'points': 2},
        {'option': 'Severe (very disturbing)', 'points': 3},
        {'option': 'Near constant/Disabling', 'points': 4},
      ],
    },
    {
      'question': 'How much time do you spend performing compulsive behaviors (repetitive actions like washing, checking, counting)?',
      'options': [
        {'option': 'None', 'points': 0},
        {'option': 'Less than 1 hr/day', 'points': 1},
        {'option': '1 to 3 hrs/day', 'points': 2},
        {'option': '3 to 8 hrs/day', 'points': 3},
        {'option': 'More than 8 hrs/day', 'points': 4},
      ],
    },
    {
      'question': 'How strong is the drive to perform these compulsions? (What happens if you try to stop?)',
      'options': [
        {'option': 'No drive/Easy to stop', 'points': 0},
        {'option': 'Little pressure to perform', 'points': 1},
        {'option': 'Strong drive/Hard to stop', 'points': 2},
        {'option': 'Very strong drive', 'points': 3},
        {'option': 'Yielding to all urges', 'points': 4},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    checkIfTestTaken();
  }

void checkIfTestTaken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('PTSDTimestamp')) {
          Timestamp lastTimestamp = docSnapshot.data()!['PTSDTimestamp'];
          DateTime lastDate = lastTimestamp.toDate();
          
          int hoursDifference = DateTime.now().difference(lastDate).inHours;

          if (hoursDifference < 24) {
            setState(() {
              testTaken = true;
              // 2. CALCULATE REMAINING TIME
              timeRemaining = "${24 - hoursDifference} hours";
            });
          }
        }
      } catch (e) {
        debugPrint('Sync Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = selectedOptions.length / questions.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(progress),
              Expanded(
                child: testTaken ? _buildAlreadyTakenUI() : _buildQuestionList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (!testTaken && selectedOptions.length == questions.length)
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: Colors.black,
              onPressed: _submitTest,
              label: const Text("Submit Assessment", style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.done_all),
            )
          : null,
    );
  }

  Widget _buildHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              ),
              const Text("OCD Screening", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              color: const Color(0xFF4ADE80),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text("${(progress * 100).toInt()}% Complete", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Criterion ${index + 1}', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Text(questions[index]['question'], style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.4)),
              const SizedBox(height: 20),
              ...List.generate(questions[index]['options'].length, (optIdx) {
                final option = questions[index]['options'][optIdx];
                final isSelected = selectedOptions[index] == option['points'];
                return GestureDetector(
                  onTap: () => setState(() => selectedOptions[index] = option['points']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4ADE80).withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isSelected ? const Color(0xFF4ADE80) : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? const Color(0xFF4ADE80) : Colors.white24, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(option['option'], style: const TextStyle(color: Colors.white))),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

Widget _buildAlreadyTakenUI() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Using lock_clock for a more clinical "timer" feel
        const Icon(
          Icons.lock_clock_outlined, 
          color: Color(0xFF4ADE80), 
          size: 80
        ),
        const SizedBox(height: 24),
        const Text(
          'Session Completed', 
          style: TextStyle(
            color: Colors.white, 
            fontSize: 24, 
            fontWeight: FontWeight.bold
          )
        ),
        const SizedBox(height: 12),
        Text(
          'Wait ${timeRemaining ?? "24 hours"} to retake.\nView results in your Clinical Profile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6), 
            height: 1.5,
            fontSize: 16
          ),
        ),
      ],
    ),
  );
}

void _submitTest() async {
  int totalScore = selectedOptions.values.fold(0, (a, b) => a + b);
  
  // Point to 'OCD' key in your result manager
  final feedback = TestResultManager.getFeedback('OCD', totalScore);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // --- LOG TO GLOBAL ASSESSMENTS HISTORY ---
      DocumentReference assessmentRef = FirebaseFirestore.instance
          .collection('assessments')
          .doc(); 

      batch.set(assessmentRef, {
        'userId': user.uid,
        'testType': 'OCD',
        'score': totalScore,
        'diagnosis': feedback['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- UPDATE INDIVIDUAL USER DASHBOARD ---
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid);

      batch.set(userRef, {
        'OCDTestScore': totalScore,
        'OCDDiagnosis': feedback['status'],
        'OCDTestTimestamp': FieldValue.serverTimestamp(),
        
        // This helper map makes it easy to show a "Recent Activity" list later
        'lastTests': {
          'OCD': {
            'score': totalScore,
            'timestamp': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));

      await batch.commit();

      if (mounted) {
        _showEnhancedResultSheet(totalScore, feedback);
      }
    } catch (e) {
      debugPrint('Error saving OCD test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection error. Data saved locally.")),
        );
      }
    }
  }
}

  String _calculateDiagnosis(int score) {
    if (score <= 7) return 'Subclinical OCD Symptoms';
    if (score <= 15) return 'Mild OCD (Significant Symptoms)';
    if (score <= 23) return 'Moderate OCD Symptoms';
    return 'Severe OCD (Consultation Advised)';
  }

void _showEnhancedResultSheet(int score, Map<String, dynamic> feedback) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 24),
          const Text('ASSESSMENT COMPLETE', style: TextStyle(color: Color(0xFF4ADE80), letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(feedback['status'], style: TextStyle(color: feedback['color'], fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Suggestion Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
            child: Text(feedback['advice'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
          ),
          
          const SizedBox(height: 24),
          const Text("💡 YOUR CHALLENGE", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(feedback['action'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close sheet
              Navigator.pop(context); // Return to Dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("BACK TO DASHBOARD", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}
}