import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart'; // Ensure this matches your file path

// Screens
import 'package:niramaya/login.dart';
import 'package:niramaya/reg.dart';
import 'package:niramaya/container.dart';
import 'package:niramaya/home.dart';
import 'package:niramaya/profile.dart';

// Tests
import 'package:niramaya/deptest.dart';
import 'package:niramaya/anxiety_test.dart';
import 'package:niramaya/burnout_test.dart';
import 'package:niramaya/ocd_test.dart';
import 'package:niramaya/stress_test.dart';
import 'package:niramaya/bipolar_test.dart';
import 'package:niramaya/adhd_test.dart';
import 'package:niramaya/ptsd_test.dart';
import 'package:niramaya/eating_disorder_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyALZBs0dTdeq0rEle_uGU5RqiDpeCsDvuw",
      appId: "1:1095105677096:android:556b59f69784ff7192b21d",
      messagingSenderId: "1095105677096",
      projectId: "serenity-7e61e",
      storageBucket: "serenity-7e61e.appspot.com",
    ),
  );

  // 2. Use your NotificationService to handle ALL notification setup
  // This replaces the duplicate AwesomeNotifications().initialize call
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serenity – Your daily peace of mind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4FBF8),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4CAF93),
          secondary: Color(0xFF6EC6CA),
        ),
      ),
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashLoading();
          }

          // If logged in, go to ContainerScreen
          if (snapshot.data == true) {
            return const ContainerScreen();
          }

          // Otherwise, show Login
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/registration': (_) => const RegistrationScreen(),
        '/profile': (_) => const ProfilePage(),

        // Tests
        '/test/depression': (_) => const DepressionTestScreen(),
        '/test/anxiety': (_) => const AnxietyTestScreen(),
        '/test/burnout': (_) => const BurnoutTestScreen(),
        '/test/ocd': (_) => const OCDTestScreen(),
        '/test/stress': (_) => const StressTestScreen(),
        '/test/bipolar': (_) => const BipolarTestScreen(),
        '/test/ptsd': (_) => const PTSDTestScreen(),
        '/test/eating': (_) => const EatingDisorderTestScreen(),
        '/test/adhd': (_) => const ADHDTestScreen(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: Center(
            child: Text('No route defined for "${settings.name}"'),
          ),
        ),
      ),
    );
  }
}

class SplashLoading extends StatelessWidget {
  const SplashLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4FBF8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF4CAF93)),
            SizedBox(height: 16),
            Text(
              'Preparing your wellness space...',
              style: TextStyle(
                color: Color(0xFF2E4F4F),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}