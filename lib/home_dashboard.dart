import 'package:flutter/material.dart';
import 'dart:async';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final affirmations = [
    "You are doing your best 🌱",
    "Healing takes time",
    "Your feelings are valid",
    "You are not alone",
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), _showMoodPopup);
  }

  void _showMoodPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("How are you feeling today?"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["😄", "🙂", "😐", "😔", "😢"]
              .map((e) => GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final affirmation =
        affirmations[DateTime.now().day % affirmations.length];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Affirmation",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                affirmation,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
