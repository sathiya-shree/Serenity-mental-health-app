import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:niramaya/login.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with TickerProviderStateMixin {
  bool _obscureText = true;
  bool _isLoading = false;

  // Theme Colors
  final Color primaryMint = const Color(0xFF4ADE80);
  final Color darkGreen = const Color(0xFF064E3B);
  final Color midnightBlue = const Color(0xFF020617);

  // Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final ageController = TextEditingController();

  String? selectedGender;
  String? _passwordErrorText;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  // --- REGISTRATION LOGIC ---
  Future<void> registerUser() async {
    if (_isLoading) return;
    setState(() => _passwordErrorText = null);

    // Validation
    if (passwordController.text.length < 8) {
      setState(() => _passwordErrorText = "Minimum 8 characters required");
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => _passwordErrorText = "Passwords do not match");
      return;
    }
    if (firstNameController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your first name");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create User in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2. Save User Details to Firestore
      // NOTE: Using 'Users' (Capital U) to match your current database structure
      await FirebaseFirestore.instance.collection('Users').doc(userCredential.user!.uid).set({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'age': ageController.text.trim(),
        'gender': selectedGender,
        'createdAt': FieldValue.serverTimestamp(),
      });

      HapticFeedback.mediumImpact();
      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Registration failed");
    } catch (e) {
      Fluttertoast.showToast(msg: "An unexpected error occurred");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: darkGreen.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: primaryMint.withOpacity(0.2)),
          ),
          title: Text("Welcome to Serenity", style: TextStyle(color: primaryMint, fontWeight: FontWeight.bold)),
          content: const Text("Your sanctuary is ready. Please sign in to begin.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: Text("SIGN IN", style: TextStyle(color: primaryMint, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryMint.withOpacity(0.7), letterSpacing: 2)),
    );
  }

  Widget _glassField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, TextInputType keyboardType = TextInputType.text, String? errorText}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.orangeAccent),
        prefixIcon: Icon(icon, size: 18, color: primaryMint),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryMint.withOpacity(0.4))),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.white38),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
      ),
    );
  }

  Widget _glassDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: darkGreen),
      child: DropdownButtonFormField<String>(
        initialValue: selectedGender,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: ["Male", "Female", "Other"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: (v) => setState(() => selectedGender = v),
        decoration: InputDecoration(
          hintText: "Gender",
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryMint.withOpacity(0.4))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [darkGreen, midnightBlue]))),
          _buildAmbientDecor(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Icon(Icons.spa_rounded, size: 50, color: primaryMint),
                    const SizedBox(height: 12),
                    const Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)),
                    const SizedBox(height: 30),
                    _buildFormCard(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel("The Basics"),
              Row(
                children: [
                  Expanded(child: _glassField(firstNameController, "First Name", Icons.person_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _glassField(lastNameController, "Last Name", Icons.person_outline)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(flex: 2, child: _glassField(ageController, "Age", Icons.cake_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: _glassDropdown()),
                ],
              ),
              const SizedBox(height: 24),
              _sectionLabel("Security"),
              _glassField(emailController, "Email Address", Icons.alternate_email_rounded),
              const SizedBox(height: 16),
              _glassField(passwordController, "Password", Icons.lock_open_rounded, isPassword: true, errorText: _passwordErrorText),
              const SizedBox(height: 16),
              _glassField(confirmPasswordController, "Confirm", Icons.lock_rounded, isPassword: true),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMint,
          foregroundColor: darkGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: darkGreen))
            : const Text("START JOURNEY", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildFooter() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: RichText(
        text: TextSpan(
          text: "Already mindful? ",
          style: const TextStyle(color: Colors.white54),
          children: [
            TextSpan(text: "Sign In", style: TextStyle(color: primaryMint, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientDecor() {
    return Positioned(
      top: -100,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(shape: BoxShape.circle, color: primaryMint.withOpacity(0.05)),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    super.dispose();
  }
}