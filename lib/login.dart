import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:niramaya/reg.dart';
import 'package:niramaya/container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _obscureText = true;
  bool _isLoading = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Color primaryMint = const Color(0xFF4ADE80);
  Color darkGreen = const Color(0xFF064E3B);
  Color midnightBlue = const Color(0xFF020617);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

try {
      // ADDED .timeout() HERE
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 10)); 

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString("userID", userCredential.user?.uid ?? "");

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      
      // This is the part that moves you to the next page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ContainerScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: e.message ?? "Login failed");
    } catch (e) {
      // Handles the timeout error
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Connection timed out. Check your internet.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [darkGreen, midnightBlue],
              ),
            ),
          ),

          // Ambient glow
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryMint.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      // LOGO (FIXED PATH)
                     // Updated Logo Section
Container(
  height: 120,
  width: 120,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: primaryMint.withOpacity(0.2),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(60),
    child: Image.asset(
      "assets/Logo.png", // Pointing to your new file
      fit: BoxFit.contain, 
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.spa_rounded, size: 60, color: primaryMint);
      },
    ),
  ),
),

                      const SizedBox(height: 16),
                      const Text(
                        "SERENITY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const Text(
                        "Begin your mindful journey",
                        style:
                            TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 50),

                      // Login card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                _glassTextField(
                                  controller: emailController,
                                  hint: "Email",
                                  icon:
                                      Icons.alternate_email_rounded,
                                ),
                                const SizedBox(height: 20),
                                _glassTextField(
                                  controller: passwordController,
                                  hint: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 30),

                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : loginUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryMint,
                                      foregroundColor: darkGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: darkGreen,
                                            ),
                                          )
                                        : const Text(
                                            "SIGN IN",
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const RegistrationScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: "New to Serenity? ",
                            style:
                                const TextStyle(color: Colors.white54),
                            children: [
                              TextSpan(
                                text: "Join the circle",
                                style: TextStyle(
                                  color: primaryMint,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: primaryMint, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white38,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscureText = !_obscureText),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide:
              BorderSide(color: primaryMint.withOpacity(0.5)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
