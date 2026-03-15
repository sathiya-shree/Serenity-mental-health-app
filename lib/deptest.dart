import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/test_result_manager.dart';

class DepressionTestScreen extends StatefulWidget {
  const DepressionTestScreen({super.key});

  @override
  _DepressionTestScreenState createState() => _DepressionTestScreenState();
}

class _DepressionTestScreenState extends State<DepressionTestScreen> {
  
  String? timeRemaining; 
  
  Map<int, int> selectedOptions = {};
  bool testTaken = false;
  // FULL CLINICAL PHQ-9 QUESTIONS
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Little interest or pleasure in doing things?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
    },
    {
      'question': 'Feeling down, depressed, or hopeless?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
    },
    {
      'question': 'Trouble falling or staying asleep, or sleeping too much?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
    },
    {
      'question': 'Feeling tired or having little energy?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
    },
    {
      'question': 'Poor appetite or overeating?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
    },
    {
      'question': 'Feeling bad about yourself — or that you are a failure?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
    },
    {
      'question': 'Trouble concentrating on things (reading or watching TV)?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
    },
    {
      'question': 'Moving/speaking slowly, or being extra fidgety/restless?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
    },
    {
      'question': 'Thoughts that you would be better off dead or hurting yourself?',
      'options': [{'option': 'Not at all', 'points': 0}, {'option': 'Several days', 'points': 1}, {'option': 'More than half the days', 'points': 2}, {'option': 'Nearly every day', 'points': 3}]
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
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('DepressionTimestamp')) {
          Timestamp lastTimestamp = docSnapshot.data()!['DepressionTimestamp'];
          DateTime lastDate = lastTimestamp.toDate();
          DateTime now = DateTime.now();
          int hoursDifference = now.difference(lastDate).inHours;

          if (hoursDifference < 24) {
            setState(() {
              testTaken = true;
              timeRemaining = "${24 - hoursDifference}h remaining";
            });
          }
        }
      } catch (e) {
        debugPrint('Error checking status: $e');
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
              onPressed: _submitTest,
              label: const Text("Submit Results", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              icon: const Icon(Icons.check_circle, color: Colors.black),
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
              const Text("Depression Scale", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
          Text("${(progress * 100).toInt()}% Completed", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }
Widget _buildAlreadyTakenUI() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
              Text(questions[index]['question'], style: const TextStyle(color: Colors.white, fontSize: 17)),
              const SizedBox(height: 15),
              ...List.generate(questions[index]['options'].length, (optIdx) {
                final option = questions[index]['options'][optIdx];
                bool isSelected = selectedOptions[index] == option['points'];
                return GestureDetector(
                  onTap: () => setState(() => selectedOptions[index] = option['points']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4ADE80).withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF4ADE80) : Colors.white10),
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

void _submitTest() async {

  if (selectedOptions.length < questions.length) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please complete all questions for an accurate analysis."),
        backgroundColor: Color(0xFF4ADE80),
      ),
    );
    return;
  }

  int totalScore = selectedOptions.values.fold(0, (a, b) => a + b);

  final feedback = TestResultManager.getFeedback('Depression', totalScore);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // --- LOG TO ASSESSMENTS COLLECTION (Permanent History) ---
      DocumentReference assessmentRef = FirebaseFirestore.instance
          .collection('assessments')
          .doc(); 

      batch.set(assessmentRef, {
        'userId': user.uid,
        'testType': 'Depression',
        'score': totalScore,
        'diagnosis': feedback['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- UPDATE USER DOCUMENT (Dashboard & 24h Lockout) ---
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid);

      batch.set(userRef, {
        'DepressionTestScore': totalScore,
        'DepressionDiagnosis': feedback['status'],
        'DepressionTimestamp': FieldValue.serverTimestamp(), // Matches your initState check
        
        'lastTests': {
          'Depression': {
            'score': totalScore,
            'timestamp': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));

      // 3. Commit the batch
      await batch.commit();

      // 4. Trigger UI feedback
      if (mounted) {
        _showEnhancedResultSheet(totalScore, feedback);
      }
    } catch (e) {
      debugPrint('Error saving Depression test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cloud Sync Failed. Please check your connection."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

  String _calculateDiagnosis(int score) {
    if (score <= 4) return 'Minimal depression';
    if (score <= 9) return 'Mild depression';
    if (score <= 14) return 'Moderate depression';
    if (score <= 19) return 'Moderately severe depression';
    return 'Severe depression';
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