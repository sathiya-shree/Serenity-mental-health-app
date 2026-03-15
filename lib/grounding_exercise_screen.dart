import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroundingExerciseScreen extends StatefulWidget {
  const GroundingExerciseScreen({super.key});
  @override State<GroundingExerciseScreen> createState() => _GroundingExerciseScreenState();
}

class _GroundingExerciseScreenState extends State<GroundingExerciseScreen> {
  int _step = 0;
  final List<Map<String, dynamic>> _data = [
    {"t": "5 Things you SEE", "d": "Look for small details around you.", "i": Icons.visibility, "c": Colors.green},
    {"t": "4 Things you TOUCH", "d": "Feel your clothes or a surface.", "i": Icons.touch_app, "c": Colors.blue},
    {"t": "3 Things you HEAR", "d": "Listen for distant or nearby sounds.", "i": Icons.hearing, "c": Colors.purple},
    {"t": "2 Things you SMELL", "d": "Notice any faint scents in the air.", "i": Icons.air, "c": Colors.orange},
    {"t": "1 Thing you TASTE", "d": "Focus on the current taste in your mouth.", "i": Icons.restaurant, "c": Colors.red},
  ];

@override
  Widget build(BuildContext context) {
    var s = _data[_step];
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          // Main Exercise Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(s['i'] as IconData, size: 80, color: s['c'] as Color),
                  const SizedBox(height: 40),
                  Text(s['t'] as String, 
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(s['d'] as String, 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(color: Colors.white70, fontSize: 18)),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s['c'] as Color, 
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      if (_step < 4) {
                        setState(() => _step++);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(_step < 4 ? "Next" : "I am grounded", 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),

          // --- BACK / CLOSE BUTTON ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
