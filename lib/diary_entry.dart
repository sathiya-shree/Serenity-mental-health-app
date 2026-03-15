import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for PIN storage

// --- MAIN DIARY ENTRY SCREEN ---
class DiaryEntryScreen extends StatefulWidget {
  const DiaryEntryScreen({super.key});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  final TextEditingController _textController = TextEditingController();
  String _formattedDate = '';
  String _report = '';
  bool _loading = false;
  late GenerativeModel _aiModel;

  @override
  void initState() {
    super.initState();
    _formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    _initAI();
  }

  void _initAI() {
    const apiKey = 'GEMINI_API_KEY';
    _aiModel = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are an empathetic AI Mental Health Researcher. Provide a structured report: 1. Emotional Tone, 2. Key Themes, 3. Mindful Reflection. IMPORTANT: At the very end, add 'SCORE: X' (1-10).",
      ),
    );
  }

  Future<void> _saveToCloud(String text, String report, int score, bool isPrivate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('journal_entries').add({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateFormat('MMMM d, yyyy • hh:mm a').format(DateTime.now()),
        'text': text,
        'report': report,
        'moodScore': score,
        'isPrivate': isPrivate,
      });
    } catch (e) {
      debugPrint("Firebase Save Error: $e");
    }
  }

  void _clearMessageAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _report = '');
    });
  }

  Future<void> _generateReport() async {
    final entryText = _textController.text.trim();
    if (entryText.isEmpty) return;

    setState(() { _loading = true; _report = ''; });
    try {
      final response = await _aiModel.generateContent([Content.text("Analyze this: $entryText")]);
      String fullText = response.text ?? "";
      final RegExp scoreRegex = RegExp(r'SCORE:\s*(\d+)');
      final match = scoreRegex.firstMatch(fullText);
      int moodScore = match != null ? int.parse(match.group(1)!) : 5;
      String cleanReport = fullText.replaceAll(scoreRegex, "").trim();

      await _saveToCloud(entryText, cleanReport, moodScore, false);
      _textController.clear();
      setState(() => _report = cleanReport);
    } catch (e) {
      debugPrint("AI Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveWithoutAnalysis() async {
    final entryText = _textController.text.trim();
    if (entryText.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _saveToCloud(entryText, "This entry was saved privately.", 5, true);
      _textController.clear();
      setState(() => _report = '✅ Entry saved privately to history.');
      _clearMessageAfterDelay();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildInputArea(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                if (_report.isNotEmpty || _loading) ...[
                  const SizedBox(height: 32),
                  _buildReportSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formattedDate, style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w600, fontSize: 12)),
                const Text("Journal", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalHistoryScreen())),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: TextField(
        controller: _textController,
        maxLines: 10,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          contentPadding: const EdgeInsets.all(24),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: _loading ? null : _generateReport,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: _loading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text("Analyze with AI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 60,
            child: OutlinedButton(
              onPressed: _loading ? null : _saveWithoutAnalysis,
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: const Icon(Icons.lock_outline, color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
      child: _loading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80))) 
        : MarkdownBody(data: _report, styleSheet: MarkdownStyleSheet(p: const TextStyle(color: Colors.white, fontSize: 15))),
    );
  }
}

// --- UPDATED JOURNAL HISTORY SCREEN ---
class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  bool _isUnlocked = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    // Relock if they leave the private tab
    if (_tabController.index == 0 && _isUnlocked) {
      setState(() => _isUnlocked = false);
    }
    // Prompt for PIN when entering private tab
    if (_tabController.index == 1 && !_isUnlocked) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedPin = prefs.getString('user_pin');

    if (savedPin == null) {
      _showPinDialog(
        title: "Set Private PIN",
        buttonText: "Save PIN",
        onConfirm: (enteredPin) async {
          await prefs.setString('user_pin', enteredPin);
          setState(() => _isUnlocked = true);
        },
      );
    } else {
      _showPinDialog(
        title: "Unlock History",
        buttonText: "Unlock",
        onConfirm: (enteredPin) {
          if (enteredPin == savedPin) {
            setState(() => _isUnlocked = true);
          } else {
            _tabController.animateTo(0);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Incorrect PIN!")),
            );
          }
        },
      );
    }
  }

  void _showPinDialog({required String title, required String buttonText, required Function(String) onConfirm}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF020617),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "4-digit code",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4ADE80))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pinController.clear();
              _tabController.animateTo(0);
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80)),
            onPressed: () {
              if (_pinController.text.length == 4) {
                String input = _pinController.text;
                _pinController.clear();
                Navigator.pop(context);
                onConfirm(input);
              }
            },
            child: Text(buttonText, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(BuildContext context, DocumentReference ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF020617),
        title: const Text("Delete Entry?", style: TextStyle(color: Colors.white)),
        content: const Text("This will permanently remove this record.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.delete();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        title: const Text("Journal History", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4ADE80),
          labelColor: const Color(0xFF4ADE80),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: "AI Analysis"),
            Tab(icon: Icon(Icons.lock_outline), text: "Private"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HistoryList(showPrivate: false, onDelete: _deleteEntry),
          _isUnlocked 
              ? HistoryList(showPrivate: true, onDelete: _deleteEntry)
              : _buildLockedOverlay(),
        ],
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_person_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text("Private Section Locked", style: TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: _authenticate,
            child: const Text("Tap to Unlock", style: TextStyle(color: Color(0xFF4ADE80))),
          )
        ],
      ),
    );
  }
}

class HistoryList extends StatelessWidget {
  final bool showPrivate;
  final Function(BuildContext, DocumentReference) onDelete;
  
  const HistoryList({super.key, required this.showPrivate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('journal_entries')
          .where('userId', isEqualTo: user?.uid)
          .where('isPrivate', isEqualTo: showPrivate)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading history", style: TextStyle(color: Colors.white38)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)));
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No entries found here.", style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var item = doc.data() as Map<String, dynamic>;
            return Card(
              color: Colors.white.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                iconColor: const Color(0xFF4ADE80),
                title: Text(item['date'] ?? '', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(item['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                  onPressed: () => onDelete(context, doc.reference),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Your Entry:", style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(item['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const Divider(height: 24, color: Colors.white10),
                        const Text("Report:", style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        MarkdownBody(
                          data: item['report'] ?? '',
                          styleSheet: MarkdownStyleSheet(p: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- GRATITUDE JAR VIEW ---

