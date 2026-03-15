import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final List<String> _affirmations = [
"You are allowed to take up space 🌸",
"Your pace is perfect for you 🕊️",
"Growth takes time — and you’re growing 🌻",
"You don’t have to have it all figured out 🌊",
"Rest is productive too 🛌",
"You are worthy of good things 🍀",
"Let today unfold gently 🌼",
"You are resilient and brave 🛡️",
"Every breath is a new beginning 🌬️",
"You can handle this moment 🌤️",
"It’s okay to start again 🔄",
"You are enough, just as you are 🤎",
"Trust yourself a little more today 🌺",
"Your effort matters 🌟",
"Hard days don’t define you 🌧️",
"You are learning and evolving 🦋",
"Kindness toward yourself changes everything 💗",
"You deserve peace 🕯️",
"One thing at a time 🧩",
"You are not behind in life ⏳",
"Your story is still unfolding 📖",
"You bring light to others ✨",
"It’s okay to say no 🚦",
"Celebrate small wins 🎉",
"You are capable of beautiful things 🎨",
"You are healing, even if it’s slow 🌿",
"This feeling will pass 🌈",
"You deserve to feel safe 🤍",
"Your voice matters 🎤",
"You are doing your best — and that’s enough 🌷",
"Choose compassion over criticism 💞",
"You are stronger than yesterday 💪",
"Let go of what you can’t control 🍃",
"You are allowed to rest without guilt 🌙",
"Today, choose hope 🌅",
"You are becoming who you’re meant to be 🌺",
"Peace begins with you ☮️",
"You are more than your mistakes 🌸",
"Slow down — you’re not in a race 🐢",
"You deserve joy 🌞",
"You are supported, even when it’s unseen 🌌",
"Your heart knows the way 💖",
"Progress is progress, no matter how small 🐾",
"You are worthy of love 💓",
"Trust the timing of your life ⏰",
"You can start where you are 🏁",
"You are allowed to change 🌻",
"Give yourself credit 🌟",
"You are not alone 🤝",
"Be proud of how far you’ve come 🛤️",
"Light exists even in the dark 🕯️",
"You are capable of tough things 🧗",
"Your presence makes a difference 🌍",
"It’s okay to feel and still move forward 🌊",
"You are building strength every day 🏗️",
"Hope is always within reach 🌤️",
"You deserve softness 🌷",
"You are worthy of respect 🌼",
"Keep going — you’ve got this 🚀",
"You are creating your own path 🛤️",
"Your growth is not linear 📈",
"You are safe to be yourself 🌈",
"Each day is a new chance 🌄",
"You are more powerful than you know ⚡",
"Take it moment by moment ⏱️",
"You are allowed to feel proud 🏆",
"Your boundaries are important 🚧",
"You can rewrite your story ✍️",
"You deserve understanding 💬",
"You are a work in progress — and that’s beautiful 🎨",
"Show up for yourself today 🌞",
"You are guided and protected 🌟",
"You have overcome so much already 🛶",
"Your dreams are valid 🌠",
"You can choose calm 🌿",
"You are worthy of abundance 🌾",
"Let yourself grow at your own speed 🌱",
"You radiate strength 🌞",
"Be patient with yourself 🕰️",
"You are becoming stronger every day 💎",
"Your peace is a priority 🕊️",
"You are allowed to take breaks 🌤️",
"Keep believing in yourself 💫"

  ];

  static Future<void> initialize() async {
    // 1. INITIALIZE THE CHANNEL (Crucial: Your app won't show anything without this)
    await AwesomeNotifications().initialize(
      null, // Use null for default app icon
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Daily Affirmations',
          channelDescription: 'Mental health reminders and affirmations',
          defaultColor: const Color(0xFF4ADE80),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: true,
        )
      ],
      debug: true, // Shows errors in the console during development
    );

    // 2. CHECK PERMISSIONS
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // 3. SCHEDULE
    await schedule30Days();
  }

  static Future<void> schedule30Days() async {
    // Safety check: ensure we have at least 1 affirmation to avoid errors
    if (_affirmations.isEmpty) {
      debugPrint("Affirmation list is empty. Scheduling aborted.");
      return;
    }

    // Clear old schedules to prevent duplicates
    await AwesomeNotifications().cancelAllSchedules();

    List<String> shuffled = List.from(_affirmations);
    shuffled.shuffle(Random());

    String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    int id = 1;
    int affirmationIndex = 0;
    DateTime now = DateTime.now();

    // Schedule for the next 30 days
    for (int day = 0; day < 30; day++) {
      DateTime targetDate = now.add(Duration(days: day));

      // 3 notifications per day: 8 AM, 1 PM, 7 PM
      for (int hour in [8, 13, 19]) {
        // Use modulo (%) so it restarts the list if you have fewer than 90 strings
        String currentAffirmation = shuffled[affirmationIndex % shuffled.length];

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id++,
            channelKey: 'basic_channel',
            title: "A message for you 💛",
            body: currentAffirmation,
            notificationLayout: NotificationLayout.Default,
            category: NotificationCategory.Reminder,
          ),
          schedule: NotificationCalendar(
            year: targetDate.year,
            month: targetDate.month,
            day: targetDate.day,
            hour: hour,
            minute: 0,
            second: 0,
            millisecond: 0,
            repeats: false,
            timeZone: localTimeZone,
            allowWhileIdle: true, // Shows even when phone is in battery saver/doze
            preciseAlarm: true,   // Fires exactly at the second
          ),
        );
        affirmationIndex++;
      }
    }
    debugPrint("✅ 90 Affirmations scheduled successfully.");
  }
}