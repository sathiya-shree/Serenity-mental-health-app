import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class ZenPlayer extends StatefulWidget {
  final String title;
  final String sub;
  final IconData icon;
  final String audioUrl;
  const ZenPlayer({super.key, required this.title, required this.sub, required this.icon, required this.audioUrl});
  @override State<ZenPlayer> createState() => _ZenPlayerState();
}

class _ZenPlayerState extends State<ZenPlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    try {
      await _player.setUrl(widget.audioUrl);
      _player.playerStateStream.listen((state) {
        if (mounted) setState(() => _isPlaying = state.playing);
      });
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF064E3B), Color(0xFF020617)],
              ),
            ),
          ),
          // Blurred background decoration
          Positioned(
            top: 100,
            left: -50,
            child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4ADE80).withOpacity(0.1))),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.expand_more, color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                const Spacer(),
                // Hero Icon with Glow
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withOpacity(0.1), blurRadius: 40)],
                  ),
                  child: Icon(widget.icon, size: 100, color: const Color(0xFF4ADE80)),
                ),
                const SizedBox(height: 40),
                Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                Text(widget.sub, style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 1.2)),
                const Spacer(),
                // Playback Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _buildPlayerControls(),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Column(
      children: [
        // Simple Audio Progress (StreamBuilder)
        StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = _player.duration ?? Duration.zero;
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF4ADE80),
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: position.inSeconds.toDouble(),
                    max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                    onChanged: (val) => _player.seek(Duration(seconds: val.toInt())),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    Text(_formatDuration(duration), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                )
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _isPlaying ? _player.pause() : _player.play();
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
            child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.black),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}