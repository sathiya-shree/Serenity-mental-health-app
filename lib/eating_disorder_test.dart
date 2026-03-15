import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/test_result_manager.dart';

class EatingDisorderTestScreen extends StatefulWidget {
  
  const EatingDisorderTestScreen({super.key});

  @override
  _EatingDisorderTestScreenState createState() => _EatingDisorderTestScreenState();
}

class _EatingDisorderTestScreenState extends State<EatingDisorderTestScreen> {
    String? timeRemaining;
  Map<int, int> selectedOptions = {};
  bool testTaken = false;
  // Clinically-aligned screening questions (SCOFF and EAT-26 inspired)
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Do you make yourself sick (vomit) because you feel uncomfortably full?',
      'options': [
        {'option': 'Never', 'points': 0},
        {'option': 'Rarely', 'points': 1},
        {'option': 'Often', 'points': 2},
        {'option': 'Always', 'points': 3},
      ],
    },
    {
      'question': 'Do you worry you have lost control over how much you eat?',
      'options': [
        {'option': 'Never', 'points': 0},
        {'option': 'Rarely', 'points': 1},
        {'option': 'Often', 'points': 2},
        {'option': 'Always', 'points': 3},
      ],
    },
    {
      'question': 'Have you recently lost more than 14 pounds (approx. 6kg) in a 3-month period?',
      'options': [
        {'option': 'No', 'points': 0},
        {'option': 'Unsure', 'points': 1},
        {'option': 'Yes', 'points': 3},
      ],
    },
    {
      'question': 'Do you believe yourself to be fat when others say you are too thin?',
      'options': [
        {'option': 'Never', 'points': 0},
        {'option': 'Rarely', 'points': 1},
        {'option': 'Often', 'points': 2},
        {'option': 'Always', 'points': 3},
      ],
    },
    {
      'question': 'Would you say that food dominates your life or your daily thoughts?',
      'options': [
        {'option': 'Never', 'points': 0},
        {'option': 'Rarely', 'points': 1},
        {'option': 'Often', 'points': 2},
        {'option': 'Always', 'points': 3},
      ],
    },
    {
      'question': 'Do you find yourself preoccupied with the desire to be thinner?',
      'options': [
        {'option': 'Never', 'points': 0},
        {'option': 'Rarely', 'points': 1},
        {'option': 'Often', 'points': 2},
        {'option': 'Always', 'points': 3},
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
              label: const Text("View Assessment", style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text(
                "Nourishment Insight",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
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
              Text(
                'QUESTION ${index + 1}',
                style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Text(
                questions[index]['question'],
                style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.4),
              ),
              const SizedBox(height: 20),
              ...List.generate(
                questions[index]['options'].length,
                (optionIndex) {
                  final option = questions[index]['options'][optionIndex];
                  final isSelected = selectedOptions[index] == option['points'];
                  return GestureDetector(
                    onTap: () => setState(() => selectedOptions[index] = option['points']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4ADE80).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4ADE80) : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? const Color(0xFF4ADE80) : Colors.white24,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(option['option'], style: const TextStyle(color: Colors.white))),
                        ],
                      ),
                    ),
                  );
                },
              ),
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



// 2. BATCH WRITE SUBMISSION
void _submitTest() async {
  int totalScore = selectedOptions.values.fold(0, (a, b) => a + b);
  
  // Get feedback from manager
  final feedback = TestResultManager.getFeedback('EatingDisorder', totalScore);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // --- LOG TO ASSESSMENTS HISTORY ---
      DocumentReference assessmentRef = FirebaseFirestore.instance
          .collection('assessments')
          .doc(); 

      batch.set(assessmentRef, {
        'userId': user.uid,
        'testType': 'EatingDisorder',
        'score': totalScore,
        'diagnosis': feedback['status'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // --- UPDATE USER DASHBOARD ---
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid);

      batch.set(userRef, {
        'eatingDisorderTestScore': totalScore,
        'eatingDisorderDiagnosis': feedback['status'],
        'eatingDisorderTimestamp': FieldValue.serverTimestamp(),
        
        'lastTests': {
          'EatingDisorder': {
            'score': totalScore,
            'timestamp': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));

      // Commit everything
      await batch.commit();

      if (mounted) {
        _showEnhancedResultSheet(totalScore, feedback);
      }
    } catch (e) {
      debugPrint('Error saving Eating Disorder test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud Sync Failed. Please check connection.")),
        );
      }
    }
  }
}


  String _calculateDiagnosis(int score) {
    if (score == 0) return 'Healthy Relationship with Food';
    if (score <= 3) return 'Minimal Indicators';
    if (score <= 6) return 'Mild Indicators';
    if (score <= 10) return 'Moderate Indicators';
    return 'High Likelihood (Professional evaluation recommended)';
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