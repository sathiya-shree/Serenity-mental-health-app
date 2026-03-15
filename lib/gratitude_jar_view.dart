import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';

class GratitudeJarView extends StatefulWidget {
  const GratitudeJarView({super.key});

  @override
  State<GratitudeJarView> createState() => _GratitudeJarViewState();
}

class _GratitudeJarViewState extends State<GratitudeJarView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _quickAddController = TextEditingController();
  late AnimationController _floatingController;

  final AudioPlayer _player = AudioPlayer();
  final String audioUrl =
      "https://cdn.bensound.com/bensound-silentwaves.mp3";

  bool _isMuted = true; // ✅ default muted

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _setupAudio();
  }

  Future<void> _setupAudio() async {
    try {
      await _player.setUrl(audioUrl);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0.4); // volume when playing
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  Future<void> _toggleAudio() async {
    try {
      if (_isMuted) {
        await _player.play();
      } else {
        await _player.pause();
      }

      setState(() {
        _isMuted = !_isMuted;
      });
    } catch (e) {
      debugPrint("Audio Toggle Error: $e");
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _quickAddController.dispose();
    _player.dispose();
    super.dispose();
  }

  // ================= LOGIC =================

  Future<void> _addMemory() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('GratitudeJar')
        .add({
      'memory': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _quickAddController.clear();
    FocusScope.of(context).unfocus();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please login",
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(user.uid)
                        .collection('GratitudeJar')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF34D399),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 10, 20, 150),
                        physics: const BouncingScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data =
                              docs[index].data() as Map<String, dynamic>;

                          var timestamp =
                              data['createdAt'] as Timestamp?;

                          String dateStr = timestamp != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(timestamp.toDate())
                              : 'Today';

                          return _buildMemoryBubble(
                              index,
                              data['memory'] ?? "",
                              dateStr);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [Color(0xFF065F46), Color(0xFF022C22)],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white38, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "MEMORY JAR",
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 3,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(
              _isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: _isMuted
                  ? Colors.white38
                  : const Color(0xFF34D399),
            ),
            onPressed: _toggleAudio,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryBubble(
      int index, String text, String date) {
    bool isLeft = index % 2 == 0;

    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        double offset =
            math.sin(_floatingController.value * 2 * math.pi +
                    index) *
                8;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Padding(
            padding: EdgeInsets.only(
              left: isLeft ? 0 : 40,
              right: isLeft ? 40 : 0,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: isLeft
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 6, left: 10, right: 10),
                  child: Text(
                    date.toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFF34D399)
                          .withOpacity(0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981)
                            .withOpacity(0.25),
                        const Color(0xFF34D399)
                            .withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(30),
                      topRight: const Radius.circular(30),
                      bottomLeft:
                          Radius.circular(isLeft ? 4 : 30),
                      bottomRight:
                          Radius.circular(isLeft ? 30 : 4),
                    ),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text(
                    text,
                    textAlign:
                        isLeft ? TextAlign.left : TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B).withOpacity(0.98),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: _quickAddController,
                  style:
                      const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Drop a happy note...",
                    hintStyle: TextStyle(
                        color: Colors.white30,
                        fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _addMemory(),
                ),
              ),
              GestureDetector(
                onTap: _addMemory,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color(0xFF34D399),
                      Color(0xFF10B981)
                    ]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFF022C22),
                      size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Your gratitude journey starts here.\nAdd your first memory.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white38,
          fontSize: 16,
        ),
      ),
    );
  }
}
