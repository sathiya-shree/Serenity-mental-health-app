import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:niramaya/container.dart';
import 'login.dart';
import 'help_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isEditing = false;
  bool _isPasswordVisible = false;
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data()!;
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _emailController.text = userData['email'] ?? user!.email ?? '';
        });
      }
    } catch (e) {
      _showSnack("Failed to load profile: $e");
    }
    setState(() => _isLoading = false);
  }

  // --- Logic Functions ---

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF064E3B), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
      });
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      _showSnack("Profile updated successfully!");
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Update failed: $e");
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.length < 6) {
      _showSnack("Password must be at least 6 characters");
      return;
    }

    try {
      await user!.updatePassword(_passwordController.text.trim());
      _passwordController.clear();
      _showSnack("Password changed successfully!");
    } catch (e) {
      _showSnack("Error: Re-authenticate to change password.");
    }
  }

  // NEW: Sign Out Logic
  Future<void> _signOut() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF020617),
        title: const Text("Sign Out", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to log out?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Logout", style: TextStyle(color: Color(0xFF4ADE80)))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const LoginScreen()), 
          (route) => false
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF020617),
        title: const Text("Delete Account?", style: TextStyle(color: Colors.redAccent)),
        content: const Text("This action is permanent and cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('Users').doc(user!.uid).delete();
        await user!.delete();
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        }
      } catch (e) {
        _showSnack("Error: Please log out and log back in to delete account.");
      }
    }
  }

  // --- UI Building Blocks ---

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Please log in")));

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF020617)],
          ),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildTopNav(),
                    const SizedBox(height: 30),
                    _buildAvatar(),
                    const SizedBox(height: 30),
                    
                    _buildSectionHeader("Personal Information"),
                    _buildGlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildField("First Name", _firstNameController, Icons.person_outline),
                            _buildField("Last Name", _lastNameController, Icons.person_outline),
                            _buildField("Email Address", _emailController, Icons.email_outlined, enabled: false),
                            if (_isEditing) const SizedBox(height: 20),
                            if (_isEditing) _buildSaveButton(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader("Health Assessment Records"),
                    _buildHealthRecords(),

                    const SizedBox(height: 24),
                    _buildSectionHeader("Security & Account"),
                    _buildSecurityCard(),

                    const SizedBox(height: 40),
                    _buildDeleteButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Row(
      
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ContainerScreen())),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        const Text("Your Profile", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(
          icon: Icon(_isEditing ? Icons.close : Icons.edit_note, color: const Color(0xFF4ADE80)),
          onPressed: () => setState(() => _isEditing = !_isEditing),
        )
      ],
    );
  }

  Widget _buildAvatar() {
    String initials = (_firstNameController.text.isNotEmpty ? _firstNameController.text[0] : "U").toUpperCase();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4ADE80), width: 2)),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: Text(initials, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        Text("${_firstNameController.text} ${_lastNameController.text}", 
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

Widget _buildHealthRecords() {
  // 1. Comprehensive check for all 9 tests
  bool hasRecords = userData.containsKey('AnxietyTestScore') || 
                    userData.containsKey('DepressionTestScore') || 
                    userData.containsKey('ADHDTestScore') ||
                    userData.containsKey('PTSDTestScore') || 
                    userData.containsKey('eatingDisorderTestScore') || 
                    userData.containsKey('BurnoutTestScore') ||
                    userData.containsKey('OCDTestScore') ||
                    userData.containsKey('BipolarTestScore') ||
                    userData.containsKey('StressTestScore');

  if (!hasRecords) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text("No assessment records found.", 
          style: TextStyle(color: Colors.white.withOpacity(0.4))),
      ),
    );
  }

  return Column(
    children: [
      // 1. Anxiety (GAD-7)
      if (userData.containsKey('AnxietyTestScore'))
        _buildTestTile("Anxiety", userData['AnxietyTestScore'], userData['AnxietyDiagnosis'], Icons.waves),
      
      // 2. Depression (PHQ-9)
      if (userData.containsKey('DepressionTestScore'))
        _buildTestTile("Depression", userData['DepressionTestScore'], userData['DepressionDiagnosis'], Icons.cloud_outlined),
      
      // 3. ADHD (ASRS)
      if (userData.containsKey('ADHDTestScore'))
        _buildTestTile("ADHD", userData['ADHDTestScore'], userData['ADHDDiagnosis'], Icons.bolt),

      // 4. PTSD (PC-PTSD-5)
      if (userData.containsKey('PTSDTestScore'))
        _buildTestTile("PTSD", userData['PTSDTestScore'], userData['PTSDDiagnosis'], Icons.shield_outlined),

      // 5. Eating Disorder (SCOFF)
      if (userData.containsKey('eatingDisorderTestScore'))
        _buildTestTile("Nourishment", userData['eatingDisorderTestScore'], userData['eatingDisorderDiagnosis'], Icons.restaurant_menu),

      // 6. Burnout (BAT)
      if (userData.containsKey('BurnoutTestScore'))
        _buildTestTile("Burnout", userData['BurnoutTestScore'], userData['BurnoutDiagnosis'], Icons.local_fire_department_outlined),

      // 7. OCD (Y-BOCS)
      if (userData.containsKey('OCDTestScore'))
        _buildTestTile("OCD", userData['OCDTestScore'], userData['OCDDiagnosis'], Icons.repeat_on_outlined),

      // 8. Bipolar (MDQ)
      if (userData.containsKey('BipolarTestScore'))
        _buildTestTile("Bipolar", userData['BipolarTestScore'], userData['BipolarDiagnosis'], Icons.contrast_outlined),

      // 9. Stress (PSS)
      if (userData.containsKey('StressTestScore'))
        _buildTestTile("Stress", userData['StressTestScore'], userData['StressDiagnosis'], Icons.psychology_outlined),
    ],
  );
}

  Widget _buildTestTile(String title, dynamic score, dynamic diag, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4ADE80), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(diag ?? "Assessment Pending", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF4ADE80).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text("$score", style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled && _isEditing,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white24, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: (_isEditing && enabled) ? Colors.white.withOpacity(0.05) : Colors.transparent,
          disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4ADE80))),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), 
          style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter New Password",
              hintStyle: const TextStyle(color: Colors.white24),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white24),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white),
              child: const Text("Update Password"),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10),
          ),
          // Integrated Sign Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text("Sign Out of Account"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white10),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80), foregroundColor: Colors.black),
        onPressed: _saveProfile,
        child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return TextButton(
      onPressed: _deleteAccount,
      child: const Text("Delete Account Permanently", style: TextStyle(color: Colors.redAccent, fontSize: 14)),
    );
  }
}