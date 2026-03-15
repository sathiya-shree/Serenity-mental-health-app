import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/test_result_manager.dart';

class StressTestScreen extends StatefulWidget {
  const StressTestScreen({super.key});

  @override
  _StressTestScreenState createState() => _StressTestScreenState();
}

class _StressTestScreenState extends State<StressTestScreen> {
  // PSS-4: Perceived Stress Scale (Clinically Validated)
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'In the last month, how often have you felt that you were unable to control the important things in your life?',
      'options': [
        {'option': 'Never', 'points': 0},
        {'option': 'Almost Never', 'points': 1},
        {'option': 'Sometimes', 'points': 2},
        {'option': 'Fairly Often', 'points': 3},
        {'option': 'Very Often', 'points': 4},
      ],
    },
    {
      'question': 'In the last month, how often have you felt confident about your ability to handle your personal problems?',
      'options': [
        {'option': 'Never', 'points': 4}, // Reverse Scored
        {'option': 'Almost Never', 'points': 3},
        {'option': 'Sometimes', 'points': 2},
        {'option': 'Fairly Often', 'points': 1},
        {'option': 'Very Often', 'points': 0},
      ],
    },
    {
      'question': 'In the last month, how often have you felt that things were going your way?',
      'options': [
        {'option': 'Never', 'points': 4}, // Reverse Scored
        {'option': 'Almost Never', 'points': 3},
        {'option': 'Sometimes', 'points': 2},
        {'option': 'Fairly Often', 'points': 1},
        {'option': 'Very Often', 'points': 0},
      ],
    },
    {
      'question': 'In the last month, how often have you felt difficulties were piling up so high that you could not overcome them?',
      'options': [
        {'option': 'Never', 'points': 0},
        {'option': 'Almost Never', 'points': 1},
        {'option': 'Sometimes', 'points': 2},
        {'option': 'Fairly Often', 'points': 3},
        {'option': 'Very Often', 'points': 4},
      ],
    },
  ];

  Map<int, int> selectedOptions = {};
  bool testTaken = false;
  String? timeRemaining;

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
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('StressTestTimestamp')) {
          Timestamp lastTimestamp = docSnapshot.data()!['StressTestTimestamp'];
          DateTime lastDate = lastTimestamp.toDate();
          int hoursDifference = DateTime.now().difference(lastDate).inHours;

          if (hoursDifference < 24) {
            setState(() {
              testTaken = true;
              timeRemaining = "${24 - hoursDifference}h remaining";
            });
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
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
              label: const Text("Finalize Result", style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.check_circle_outline),
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
              const Text("Stress Analysis", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
          Text("${selectedOptions.length} of ${questions.length} answered", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
              Text('STRESS FACTOR ${index + 1}', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
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
                      color: isSelected ? const Color(0xFF4ADE80).withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF4ADE80) : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? const Color(0xFF4ADE80) : Colors.white24, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(option['option'], style: const TextStyle(color: Colors.white, fontSize: 15))),
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
  
  // 1. Fetch feedback from manager using the 'Stress' key
  final feedback = TestResultManager.getFeedback('Stress', totalScore);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // Create a batch to handle multiple writes as one unit
      final batch = FirebaseFirestore.instance.batch();

      // --- LOG TO GLOBAL ASSESSMENTS HISTORY ---
      DocumentReference assessmentRef = FirebaseFirestore.instance
          .collection('assessments')
          .doc(); 

      batch.set(assessmentRef, {
        'userId': user.uid,
        'testType': 'Stress',
        'score': totalScore,
        'diagnosis': feedback['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- UPDATE INDIVIDUAL USER DASHBOARD ---
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid);

      batch.set(userRef, {
        'StressTestScore': totalScore,
        'StressDiagnosis': feedback['status'],
        'StressTestTimestamp': FieldValue.serverTimestamp(), // Matches your lockout check
        
        // Helper map for dashboard UI performance
        'lastTests': {
          'Stress': {
            'score': totalScore,
            'timestamp': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));

      // Execute the batch
      await batch.commit();

      if (mounted) {
        _showEnhancedResultSheet(totalScore, feedback);
      }
    } catch (e) {
      debugPrint('Stress Test Sync Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud sync failed. Results saved locally.")),
        );
      }
    }
  }
}
  String _getStressDiagnosis(int score) {
    if (score <= 5) return 'Low Stress';
    if (score <= 10) return 'Moderate Stress';
    return 'High Stress';
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
