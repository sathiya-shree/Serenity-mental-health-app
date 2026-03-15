import 'package:flutter/material.dart';

/// A class to hold assessment results instead of a dynamic Map
class ResultData {
  final String status;
  final Color color;
  final String advice;
  final String action;

  ResultData({
    required this.status, 
    required this.color, 
    required this.advice, 
    required this.action
  });

  // Convert to map if your existing UI still strictly requires it
  Map<String, dynamic> toMap() => {
    "status": status,
    "color": color,
    "advice": advice,
    "action": action,
  };
}

class TestResultManager {
  static Map<String, dynamic> getFeedback(String testName, int score) {
    // We normalize the testName to handle case sensitivity
    final normalizedName = testName.trim().toLowerCase();

    switch (normalizedName) {
      case 'depression':
        if (score <= 4) return _data("Minimal", Colors.green, "You're doing great! Keep maintaining your routine.", "Try a 5-minute gratitude log.");
        if (score <= 9) return _data("Mild", Colors.yellow, "A bit of a low mood. Prioritize sleep and sunlight.", "Go for a 15-minute walk today.");
        if (score <= 14) return _data("Moderate", Colors.orange, "You may be struggling. Consider talking to a friend.", "Schedule a 'worry time' of 10 mins.");
        return _data("Severe", Colors.red, "Significant distress. Please consult a professional.", "Contact a helpline or a doctor.");

      case 'anxiety':
        if (score <= 4) return _data("Minimal", Colors.green, "Your anxiety levels are low. Stay mindful!", "Try 2 minutes of box breathing.");
        if (score <= 9) return _data("Mild", Colors.yellow, "Feeling a bit on edge? Try to limit caffeine.", "Listen to a 5-minute calm soundscape.");
        if (score <= 14) return _data("Moderate", Colors.orange, "Anxiety is affecting you. Try grounding exercises.", "Use the 5-4-3-2-1 grounding technique.");
        return _data("Severe", Colors.red, "High anxiety. It's okay to ask for professional help.", "Reach out to a therapist or counselor.");

      case 'burnout':
        if (score <= 7) return _data("Engaged", Colors.green, "You have high energy and low exhaustion.", "Do one small thing just for fun today.");
        if (score <= 15) return _data("Mild Stress", Colors.yellow, "You're starting to feel the weight. Time to rest.", "Set a 'hard stop' time for work tonight.");
        if (score <= 22) return _data("Moderate Burnout", Colors.orange, "You are emotionally overextended.", "Delegate one task to someone else today.");
        return _data("Severe Burnout", Colors.red, "Your battery is empty. You need a real break.", "Take a full day off from all responsibilities.");

      case 'stress':
        if (score <= 10) return _data("Low", Colors.green, "Stress is manageable. Keep it up!", "Take 3 deep belly breaths.");
        if (score <= 20) return _data("Moderate", Colors.orange, "Work-life balance might be tipping. Slow down.", "Unplug from screens for 1 hour.");
        return _data("High", Colors.red, "You are nearing burnout. Immediate rest is needed.", "Delegate one task to someone else today.");

      case 'adhd':
        if (score <= 13) return _data("Unlikely", Colors.green, "Low symptoms of ADHD detected.", "Use a planner for one small goal.");
        if (score <= 17) return _data("Possible", Colors.orange, "Some focus issues. Try structured lists.", "Try the Pomodoro (25m work/5m break).");
        return _data("Likely", Colors.red, "Symptoms are consistent with ADHD. See a specialist.", "Break a big task into 3 tiny steps.");

      case 'ocd':
        if (score <= 7) return _data("Subclinical", Colors.green, "Minimal symptoms. No cause for concern.", "Practice 'letting go' of a small urge.");
        if (score <= 15) return _data("Mild", Colors.yellow, "Noticeable thoughts, but manageable.", "Delay a ritual by just 2 minutes.");
        return _data("Moderate/Severe", Colors.red, "OCD is impacting your life. Therapy (CBT/ERP) helps!", "Look into 'Exposure Response Prevention'.");

      case 'bipolar':
      case 'bipolar disorder': // Handles both variations
        if (score <= 7) return _data("Stable", Colors.green, "Your mood seems stable right now.", "Track your sleep for the next 3 days.");
        return _data("Variation", Colors.orange, "Mood fluctuations noted. Monitor your sleep patterns.", "Discuss these mood shifts with a doctor.");

      case 'ptsd':
      case 'ptsd test':
        if (score <= 30) return _data("Low", Colors.green, "Few trauma-related symptoms detected.", "Write down one thing that feels safe.");
        return _data("High", Colors.red, "You may be experiencing trauma symptoms.", "Focus on gentle 'grounding' techniques.");

      case 'eating disorder':
      case 'nourishment':
        if (score <= 2) return _data("Low Risk", Colors.green, "Healthy relationship with food/body.", "Eat a meal mindfully, without a phone.");
        return _data("Risk Detected", Colors.red, "Food habits may be a concern. Support is available.", "Talk to a nutritionist or counselor.");

      default:
        return _data("Completed", Colors.blue, "Thank you for checking in.", "Keep tracking your daily mood!");
    }
  }

  static Map<String, dynamic> _data(String status, Color color, String advice, String action) {
    return {"status": status, "color": color, "advice": advice, "action": action};
  }
}