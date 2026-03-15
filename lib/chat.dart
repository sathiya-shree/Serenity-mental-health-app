import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  double _ttsVolume = 0.0;

  bool _isTyping = false;
  bool _isInitializing = true;
  bool _speechEnabled = false;
  bool _isListening = false;

  Color _topColor = const Color(0xFF064E3B);
  final Color _bottomColor = const Color(0xFF020617);

  final List<Content> _chatHistory = [
    Content('model', [
      TextPart("Hello! I'm Dawn, your mental health companion. How are you feeling in this beautiful moment? 🌿")
    ]),
  ];

  late GenerativeModel _model;
  late ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _initDawn();
    _initVoice();
  }

  // --- LIFECYCLE: CLEANUP ---
  @override
  void dispose() {
    _flutterTts.stop();         // Stop speaking immediately on exit
    _speechToText.stop();       // Stop mic on exit
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initVoice() async {
    _speechEnabled = await _speechToText.initialize();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Natural human speed
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setVolume(_ttsVolume);
    setState(() {});
  }
  void _speak(String text) async {
  await _flutterTts.setVolume(_ttsVolume); // Ensure current volume is applied
  await _flutterTts.speak(text);
}

  Future<void> _initDawn() async {
    // Note: Always secure your API keys in production!
    const apiKey = 'AIzaSyB4lJlYPOVmQABrVncVGwZgA2tsdS3hvFk';
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', // Corrected version
        apiKey: apiKey,
        systemInstruction: Content.system(
            "You are the 'Safe Haven' AI. Your goal is to stabilize users in distress. "
            "1. Use Socratic questioning to challenge anxious thoughts. "
            "2. If the user seems overwhelmed, suggest a 4-7-8 breathing exercise. "
            "3. Never judge; use validating language. "
            "4. Keep responses short (under 3 sentences)."),
      );

      _chatSession = _model.startChat(history: [
        Content.model([
          TextPart("Hello! I'm Dawn, your mental health companion. How are you feeling in this beautiful moment? 🌿")
        ])
      ]);

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint("Init Error: $e");
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _saveMessageToFirestore(String role, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('chats').add({
        'role': role,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });
    } catch (e) {
      debugPrint("Firestore Error: $e");
    }
  }

  Future<void> _saveChatToHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _chatHistory.length <= 1) return;
    HapticFeedback.mediumImpact();
    try {
      final List<Map<String, dynamic>> messages = _chatHistory.map((content) {
        return {
          'role': content.role,
          'text': content.parts.whereType<TextPart>().map((e) => e.text).join(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('ChatHistory')
          .add({
        'date': FieldValue.serverTimestamp(),
        'preview': messages.length > 1 ? messages.last['text'] : "New Conversation",
        'messages': messages,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✨ Conversation saved to history")),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  void _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping || _isInitializing) return;

    await _flutterTts.stop(); // Stop current speech if user starts new message

    _messageController.clear();
    setState(() {
      _chatHistory.add(Content('user', [TextPart(text)]));
      _isTyping = true;
    });
    _scrollToBottom();

    await _saveMessageToFirestore('user', text);

    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      String rawResponse = response.text ?? "";
      _updateSentimentUI(rawResponse);
      String cleanText = rawResponse.replaceAll(RegExp(r'\[.*?\]'), '').trim();

      setState(() {
        _chatHistory.add(Content('model', [TextPart(cleanText)]));
        _isTyping = false;
      });

      await _saveMessageToFirestore('model', cleanText);
      _speak(cleanText);
    } catch (e) {
      setState(() {
        _isTyping = false;
        _chatHistory.add(Content('model', [
          TextPart("I lost my train of thought for a second. Could you repeat that?")
        ]));
      });
    }
    _scrollToBottom();
  }

  void _startListening() async {
    await _speechToText.listen(onResult: (result) {
      setState(() {
        _messageController.text = result.recognizedWords;
        if (result.finalResult) {
          _isListening = false;
          _handleSendMessage();
        }
      });
    });
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }


  void _updateSentimentUI(String text) {
    setState(() {
      if (text.contains("[HAPPY]")) {
        _topColor = const Color(0xFF1E40AF);
      } else if (text.contains("[SAD]")) {
        _topColor = const Color(0xFF312E81);
      } else if (text.contains("[STRESSED]")) {
        _topColor = const Color(0xFF4C1D95);
      } else {
        _topColor = const Color(0xFF064E3B);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Dawn",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ChatHistoryPage())),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.white70),
            onPressed: _saveChatToHistory,
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_topColor, _bottomColor],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final content = _chatHistory[index];
                  final isUser = content.role == 'user';
                  final text = content.parts
                      .whereType<TextPart>()
                      .map((e) => e.text)
                      .join();
                  return _buildChatBubble(text, isUser);
                },
              ),
            ),
            if (_isTyping)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Dawn is thinking...",
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    );
  }

Widget _buildInputArea() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: const BoxDecoration(
      color: Colors.black38,
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    child: SafeArea(
      child: Row(
        children: [
          IconButton(
  icon: Icon(
    _isListening ? Icons.mic : Icons.mic_none,
    // Active (Listening) = Green, Idle = Muted White
    color: _isListening ? const Color(0xFF4ADE80) : Colors.white24, 
  ),
  onPressed: _isListening ? _stopListening : _startListening,
),
          // 1. MIC BUTTON
        IconButton(
  icon: Icon(
    _ttsVolume == 0 ? Icons.volume_off : Icons.volume_up,
    // Sound On = Green, Muted = Muted White
    color: _ttsVolume > 0 ? const Color(0xFF4ADE80) : Colors.white24,
    size: 22,
  ),
  onPressed: () {
    setState(() {
      if (_ttsVolume > 0) {
        _ttsVolume = 0.0;
      } else {
        _ttsVolume = 0.5; // Unmute to 50%
      }
      _flutterTts.setVolume(_ttsVolume);
    });
  },
),
          // 3. TEXT FIELD
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Talk to Dawn...",
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),

          // 4. SEND BUTTON
          CircleAvatar(
            backgroundColor: const Color(0xFF4ADE80),
            radius: 18,
            child: IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Color(0xFF064E3B), size: 18),
              onPressed: _handleSendMessage,
            ),
          ),
        ],
      ),
    ),
  );
}
}
// --- CHAT HISTORY SCREEN ---

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  String _searchQuery = "";

  Future<void> _deleteSession(List<QueryDocumentSnapshot> session) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in session) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session deleted"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text("Reflections", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search your reflections...",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4ADE80)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('userId', isEqualTo: currentUserId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No history found 🌿", style: TextStyle(color: Colors.white38)));
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = docs.where((doc) {
                  final text = (doc['text'] as String? ?? "").toLowerCase();
                  return text.contains(_searchQuery);
                }).toList();

                // Grouping Logic (Sessions within 10 mins)
                List<List<QueryDocumentSnapshot>> groupedSessions = [];
                if (filteredDocs.isNotEmpty) {
                  List<QueryDocumentSnapshot> currentSession = [filteredDocs[0]];
                  for (int i = 1; i < filteredDocs.length; i++) {
                    final prevTime = (filteredDocs[i - 1]['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final currTime = (filteredDocs[i]['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    if (prevTime.difference(currTime).inMinutes.abs() < 10) {
                      currentSession.add(filteredDocs[i]);
                    } else {
                      groupedSessions.add(List.from(currentSession));
                      currentSession = [filteredDocs[i]];
                    }
                  }
                  groupedSessions.add(currentSession);
                }

                return ListView.builder(
                  itemCount: groupedSessions.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final session = groupedSessions[index];
                    final firstMsg = session.first.data() as Map<String, dynamic>;
                    final date = (firstMsg['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SessionDetailScreen(messages: session)),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0x1A4ADE80),
                              child: Icon(Icons.auto_awesome, color: Color(0xFF4ADE80), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text(firstMsg['text'] ?? "Session", maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 15)),
                                  Text("${session.length} interactions", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white24),
                              onPressed: () => _showDeleteDialog(session),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(List<QueryDocumentSnapshot> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Session?", style: TextStyle(color: Colors.white)),
        content: const Text("Permanently remove this conversation?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () { Navigator.pop(context); _deleteSession(session); }, child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}

// --- SESSION DETAIL SCREEN ---

class SessionDetailScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> messages;
  const SessionDetailScreen({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final sortedMessages = messages.reversed.toList();
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text("Session Detail", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedMessages.length,
        itemBuilder: (context, index) {
          final data = sortedMessages[index].data() as Map<String, dynamic>;
          final bool isBot = data['role'] == 'model';
          return Align(
            alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isBot ? const Color(0xFF1E293B) : const Color(0xFF4ADE80).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isBot ? Colors.white10 : const Color(0xFF4ADE80).withOpacity(0.2)),
              ),
              child: Text(data['text'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            ),
          );
        },
      ),
    );
  }
}