import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/test_result_manager.dart';

class BurnoutTestScreen extends StatefulWidget {
  const BurnoutTestScreen({super.key});

  @override
  _BurnoutTestScreenState createState() => _BurnoutTestScreenState();
}

class _BurnoutTestScreenState extends State<BurnoutTestScreen> {
  // Questions mapped to the same structure as your Anxiety test
  final List<Map<String, dynamic>> questions = [
    {'question': 'Do you feel emotionally exhausted or drained by your daily responsibilities?', 'options': _options},
    {'question': 'Do you feel tired even after getting what should be enough rest?', 'options': _options},
    {'question': 'Do you feel detached or indifferent toward work, studies, or daily tasks?', 'options': _options},
    {'question': 'Do you feel a lack of motivation or enthusiasm for things you once cared about?', 'options': _options},
    {'question': 'Do you feel overwhelmed by your workload or responsibilities?', 'options': _options},
    {'question': 'Do you find it hard to concentrate or stay focused?', 'options': _options},
    {'question': 'Do you feel irritable, frustrated, or impatient more often than usual?', 'options': _options},
    {'question': 'Do you feel like your efforts are not appreciated or effective?', 'options': _options},
    {'question': 'Do you avoid tasks because they feel mentally exhausting?', 'options': _options},
    {'question': 'Do you feel physically unwell (headaches, tension, fatigue) due to stress?', 'options': _options},
  ];

  static const List<Map<String, dynamic>> _options = [
    {'option': 'Never', 'points': 0},
    {'option': 'Sometimes', 'points': 1},
    {'option': 'Often', 'points': 2},
    {'option': 'Everyday', 'points': 3},
  ];

  Map<int, int> selectedOptions = {};
  bool testTaken = false;
  String? timeRemaining;

  @override
  void initState() {
    super.initState();
    _checkIfTestTaken();
  }

  // 24-Hour Refresh Logic to match Anxiety Screen
  void _checkIfTestTaken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('BurnoutTimestamp')) {
          Timestamp lastTimestamp = docSnapshot.data()!['BurnoutTimestamp'];
          DateTime lastDate = lastTimestamp.toDate();
          int hoursDifference = DateTime.now().difference(lastDate).inHours;

          if (hoursDifference < 24) {
            setState(() {
              testTaken = true;
              timeRemaining = "${24 - hoursDifference}h";
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
              label: const Text("Submit Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.analytics_outlined),
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
              const Text("Burnout Scale", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
          Text("${(progress * 100).toInt()}% Analysed", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
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
              Text('Question ${index + 1}', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Text(questions[index]['question'], style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              ...List.generate(questions[index]['options'].length, (optIdx) {
                final option = questions[index]['options'][optIdx];
                final isSelected = selectedOptions[index] == option['points'];
                return GestureDetector(
                  onTap: () => setState(() => selectedOptions[index] = option['points']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4ADE80).withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isSelected ? const Color(0xFF4ADE80) : Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? const Color(0xFF4ADE80) : Colors.white24, size: 20),
                        const SizedBox(width: 12),
                        Text(option['option'], style: const TextStyle(color: Colors.white)),
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
  
  // 1. Get the comprehensive feedback from your Manager
  final feedback = TestResultManager.getFeedback('Burnout', totalScore);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // --- LOG TO ASSESSMENTS COLLECTION (History) ---
      // This creates a unique record for every time they take the test
      DocumentReference assessmentRef = FirebaseFirestore.instance
          .collection('assessments')
          .doc(); 

      batch.set(assessmentRef, {
        'userId': user.uid,
        'testType': 'Burnout',
        'score': totalScore,
        'diagnosis': feedback['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- UPDATE USER DOCUMENT (Dashboard & Lockout) ---
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid);

      batch.set(userRef, {
        'BurnoutTestScore': totalScore,
        'BurnoutDiagnosis': feedback['status'],
        'BurnoutTimestamp': FieldValue.serverTimestamp(), // Used for your 24h check
        
        // This 'lastTests' map ensures your HomeScreen Dashboard reflects the data
        'lastTests': {
          'Burnout': {
            'score': totalScore,
            'timestamp': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));

      // 2. Commit the batch
      await batch.commit();

      // 3. Show the insight sheet
      if (mounted) {
        _showEnhancedResultSheet(totalScore, feedback);
      }
      
    } catch (e) {
      debugPrint('Error saving burnout results: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud Sync Failed. Please try again.")),
        );
      }
    }
  }
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