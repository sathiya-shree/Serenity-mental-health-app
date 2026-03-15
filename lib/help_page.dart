import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showOnboarding) {
        _showWalkthrough();
        _showOnboarding = false;
      }
    });
  }

  void _showWalkthrough() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF064E3B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Welcome to Help Center 🌿",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Here you can understand how Serenity works, "
          "explore features, and access emergency support if needed.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it",
                style: TextStyle(color: Color(0xFF4ADE80))),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------- MAIN UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF064E3B), Color(0xFF020617)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTopNav(context),
                  const SizedBox(height: 30),

                  _buildDivider(),

                  _buildModuleTile(
                    icon: Icons.info_outline,
                    title: "About Serenity",
                    content:
                        "AI-powered mental wellness companion providing preventive care, behavioral support, and crisis intervention.",
                  ),

                  _buildModuleTile(
  icon: Icons.psychology,
  title: "Psychological Assessments",
  content:
      "Includes PHQ-9, GAD-7, Stress, Burnout, OCD, Bipolar, ADHD, PTSD & Eating Disorder screening.\n\n"
      "24-hour retake restriction and risk streak monitoring.",
),

_buildModuleTile(
  icon: Icons.spa,
  title: "SOS Calm",
  content:
      "5-4-3-2-1 grounding technique and guided breathing exercises "
      "for immediate emotional stabilization.",
),

_buildModuleTile(
  icon: Icons.smart_toy,
  title: "AI Support Chatbot",
  content:
      "Conversational emotional support and coping suggestions.\n"
      "Not a substitute for professional therapy.",
),

_buildModuleTile(
  icon: Icons.menu_book,
  title: "Journal & Cognitive Tools",
  content:
      "Includes:\n"
      "- Private Diary (secure journaling)\n"
      "- Optional AI emotional tone analysis\n"
      "- Thought Flip (cognitive reframing)\n"
      "- Worry Box (externalizing distressing thoughts)\n"
      "- Gratitude Jar (positive reflection practice)",
),

_buildModuleTile(
  icon: Icons.track_changes,
  title: "Daily Wins",
  content:
      "Includes:\n"
      "- Percentage-based completion tracking\n"
      "- Daily streak computation\n"
      "- Weekly analytics visualization",
),

_buildModuleTile(
  icon: Icons.medication_liquid_rounded,
  title: "Health Log",
  content:
      "Percentage completion logic and streak system.\n"
      "Includes medication and sleep reminders.\n\n"
      "Notifications for:\n"
      "- Medication reminders\n"
      "- Sleep scheduling\n"
      "- Habit consistency\n"
      "- Daily affirmations",
),

_buildModuleTile(
  icon: Icons.music_note,
  title: "Zen Library",
  content:
      "Shows helpful mental wellness videos and reading materials "
      "based on your mood and assessment results.\n\n"
      "Includes:\n"
      "- Breathing exercises\n"
      "- Meditation\n"
      "- CBT tips\n"
      "- Sleep help\n"
      "- Focus videos\n\n"
      "You can save favorite videos, and read helpful articles.\n"
),
                        
               

                  const SizedBox(height: 20),

                  // 🚨 Emergency Highlight
                  _buildEmergencyCard(),

                  const SizedBox(height: 30),

                  _buildSectionHeader("Frequently Asked Questions"),

                  _buildFAQTile(
                      "Is my data private?",
                      "Yes. Serenity uses secure Firebase authentication and encrypted cloud storage."),

                  _buildFAQTile(
                      "Can Serenity diagnose me?",
                      "No. Serenity provides screening and support tools, not medical diagnoses."),

                  _buildFAQTile(
                      "When should I seek professional help?",
                      "If you experience persistent sadness, suicidal thoughts, panic attacks, or functional impairment."),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- MODULE TILE ----------------
  Widget _buildModuleTile(
      {required IconData icon,
      required String title,
      required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ExpansionTile(
        collapsedIconColor: const Color(0xFF4ADE80),
        iconColor: const Color(0xFF4ADE80),
        leading: Icon(icon, color: const Color(0xFF4ADE80)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(content,
                style:
                    const TextStyle(color: Colors.white70, height: 1.6)),
          )
        ],
      ),
    );
  }

  // ---------------- FAQ TILE ----------------
  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      collapsedIconColor: Colors.white70,
      iconColor: Colors.white,
      title: Text(question,
          style: const TextStyle(color: Colors.white)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer,
              style: const TextStyle(
                  color: Colors.white70, height: 1.6)),
        )
      ],
    );
  }

  // ---------------- EMERGENCY CARD ----------------
  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Emergency Support: If you are in immediate danger or experiencing severe distress, contact local emergency services or use the Crisis Support module immediately.",
              style:
                  TextStyle(color: Colors.white, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
// ---------------- SECTION HEADER ----------------
Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16, left: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4ADE80),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    ),
  );
}
  // ---------------- ANIMATED DIVIDER ----------------
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF4ADE80).withOpacity(0.6),
            Colors.transparent
          ],
        ),
      ),
    );
  }

  // ---------------- TOP NAV ----------------
  Widget _buildTopNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white, size: 20),
        ),
        const Text(
          "Help & Support",
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}