import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class PerspectiveShiftScreen extends StatefulWidget {
  const PerspectiveShiftScreen({super.key});

  @override
  State<PerspectiveShiftScreen> createState() => _PerspectiveShiftScreenState();
}

class _PerspectiveShiftScreenState extends State<PerspectiveShiftScreen>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  bool _isFront = true;
  bool _isLoadingAI = false;

  final TextEditingController _negativeController = TextEditingController();
  final TextEditingController _positiveController = TextEditingController();

  String? _selectedDistortion;

  // IMPORTANT: Move this to a secure environment variable later!
  static const String _apiKey = 'AIzaSyB4lJlYPOVmQABrVncVGwZgA2tsdS3hvFk';
  late GenerativeModel _model;

  final Map<String, Map<String, String>> _distortionData = {
    "Catastrophizing": {
      "desc": "Predicting the worst possible outcome.",
      "tip": "Ask: What is the most likely middle-ground outcome?"
    },
    "Mind Reading": {
      "desc": "Assuming you know what others are thinking.",
      "tip": "Ask: Do I have evidence, or am I mind-reading?"
    },
    "All-or-Nothing": {
      "desc": "Seeing things as only perfect or a failure.",
      "tip": "Ask: What does the 50% success mark look like?"
    },
    "Personalization": {
      "desc": "Blaming yourself for external events.",
      "tip": "Ask: What other factors played a role in this?"
    },
  };

  @override
  void initState() {
    super.initState();
    _flipController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);

    _breathController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview', // Updated to a stable model name
      apiKey: _apiKey,
      systemInstruction: Content.system(
          "You are 'Dawn'. Validate the user's struggle, then provide a 2-sentence CBT reframe."),
    );
  }
  @override
  void dispose() {
    _flipController.dispose();
    _breathController.dispose();
    _negativeController.dispose();
    _positiveController.dispose();
    super.dispose();
  }

  Future<void> _getAISuggestion() async {
    if (_negativeController.text.trim().isEmpty || _selectedDistortion == null) return;
    setState(() => _isLoadingAI = true);
    try {
      final response = await _model.generateContent([
        Content.text(
            "Thought: ${_negativeController.text}. Pattern: $_selectedDistortion. Reframe this.")
      ]);
      if (response.text != null) {
        setState(() => _positiveController.text = response.text!.trim());
      }
    } catch (e) {
      debugPrint("AI Error: $e");
    } finally {
      setState(() => _isLoadingAI = false);
    }
  }

  void _flipCard() {
    FocusScope.of(context).unfocus(); // Close keyboard before flipping
    if (_isFront) {
      if (_negativeController.text.trim().isEmpty || _selectedDistortion == null) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a thought and select a pattern.")),
        );
        return;
      }
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  InputDecoration _glassInput(String hint) {
    return InputDecoration(
      isDense: true, // Helps reduce height for overflow issues
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF4ADE80))),
    );
  }

  Widget _buildFront() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: ScaleTransition(
              scale: _breathAnimation,
              child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80), shape: BoxShape.circle)),
            ),
          ),
          const SizedBox(height: 30),
          const Text("Identify the Thought",
              style: TextStyle(
                  fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Externalize what you're feeling.",
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 20),
          TextField(
            controller: _negativeController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: _glassInput("I'm feeling like..."),
          ),
          const SizedBox(height: 30),
          const Text("The Distortion",
              style: TextStyle(
                  fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Recognize the pattern.",
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
  value: _selectedDistortion,
  isExpanded: true,
  // We explicitly set the height here to handle the multi-line items
  itemHeight: 70.0, 
  dropdownColor: const Color(0xFF020617),
  iconEnabledColor: const Color(0xFF4ADE80),
  style: const TextStyle(color: Colors.white),
  decoration: _glassInput("Choose a pattern..."),
  
  // This ensures the item shown in the box looks clean and doesn't overflow
  selectedItemBuilder: (BuildContext context) {
    return _distortionData.keys.map<Widget>((String key) {
      return Text(
        key,
        style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold),
      );
    }).toList();
  },

  items: _distortionData.keys.map((key) => DropdownMenuItem(
    value: key,
    child: SizedBox(
      height: 70.0, // Matches itemHeight above
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4ADE80),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _distortionData[key]!['desc']!,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
              height: 1.2, // Adds a little line spacing
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  )).toList(),
  onChanged: (v) => setState(() => _selectedDistortion = v),
),
       
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _flipCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text("Shift Perspective",
                style: TextStyle(
                    color: Color(0xFF064E3B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const SizedBox(height: 20), // Extra space to clear system nav bar
        ],
      ),
    );
  }

  Widget _buildBack() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.favorite_rounded, color: Color(0xFFF87171), size: 30),
          const SizedBox(height: 15),
          const Text("It takes courage to challenge your thoughts.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF4ADE80), fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 30),
          const Text("Balanced View",
              style: TextStyle(
                  fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withOpacity(0.08),
                borderRadius: BorderRadius.circular(15)),
            child: Text(_distortionData[_selectedDistortion]?['tip'] ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _positiveController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: _glassInput("Try to find a middle ground..."),
          ),
          const SizedBox(height: 20),
          if (_isLoadingAI)
            const CircularProgressIndicator(color: Color(0xFF4ADE80))
          else
            TextButton.icon(
              onPressed: _getAISuggestion,
              icon: const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF4ADE80)),
              label: const Text("Refine with Dawn",
                  style: TextStyle(
                      color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 30),
          TextButton(
              onPressed: _flipCard,
              child: const Text("Go Back", style: TextStyle(color: Colors.white24))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true, // Vital for avoiding the overflow when typing
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Perspective Shift",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * 3.14159;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: angle <= 1.5708
                    ? _buildFront()
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(3.14159),
                        child: _buildBack(),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
