import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  int currentTab = 0;
  String selectedMood = "Calm";
  Set<String> favorites = {};
  String searchQuery = "";
  String activeFilter = "All";

  final int anxietyScore = 18;
  final int depressionScore = 12;

  // ---------------- DATA ---------------- //

  final List<Map<String, String>> scienceArticles = [
    {
      "title": "Neuroplasticity: Rewiring Your Brain",
      "url": "https://www.healthline.com/health/rewiring-your-brain",
      "time": "4 min read"
    },
    {
      "title": "The Gut-Brain Axis & Depression",
      "url":
          "https://www.health.harvard.edu/diseases-and-conditions/the-gut-brain-connection",
      "time": "6 min read"
    },
    {
      "title": "Benefits of Box Breathing",
      "url": "https://www.webmd.com/balance/what-is-box-breathing",
      "time": "3 min read"
    }
  ];

  final List<Map<String, String>> curatedBooks = [
    {
      "title": "The Body Keeps the Score",
      "author": "Bessel van der Kolk",
      "url":
          "https://www.google.com/search?tbm=bks&q=The+Body+Keeps+the+Score",
      "time": "12 min summary"
    },
    {
      "title": "Atomic Habits",
      "author": "James Clear",
      "url":
          "https://www.google.com/search?tbm=bks&q=Atomic+Habits+James+Clear",
      "time": "8 min summary"
    },
    {
      "title": "Reasons to Stay Alive",
      "author": "Matt Haig",
      "url":
          "https://www.google.com/search?tbm=bks&q=Reasons+to+Stay+Alive+Matt+Haig",
      "time": "5 min summary"
    }
  ];

  final List<Map<String, String>> practiceItems = [
    {
      "title": "5-4-3-2-1 Grounding Technique",
      "desc": "Identify 5 things you see, 4 you can touch...",
      "url": "https://www.healthline.com/health/grounding-techniques"
    },
    {
      "title": "Do Affirmations Really Work?",
      "desc": "Positive statements to rewire your self-talk.",
      "url":
          "https://www.healthline.com/health/mental-health/do-affirmations-work"
    }
  ];

  final Map<String, List<Map<String, String>>> dailyTips = {
    "Anxious": [
      {
        "title": "The 5-4-3-2-1 Rule",
        "content":
            "Acknowledge 5 things you see, 4 you can touch, 3 you hear, 2 you smell, and 1 you can taste."
      },
      {
        "title": "Cold Water Shock",
        "content":
            "Splash cold water on your face to trigger the 'Dive Reflex'."
      }
    ],
    "Low": [
      {
        "title": "Behavioral Activation",
        "content":
            "Do one tiny task, like making your bed, to break the cycle."
      },
      {
        "title": "The 2-Minute Rule",
        "content":
            "If a task takes less than 2 minutes, do it now."
      }
    ],
    "Calm": [
      {
        "title": "Digital Detox",
        "content":
            "Try leaving your phone in another room for 30 minutes."
      },
      {
        "title": "Mindful Sip",
        "content":
            "Drink your tea slowly. Feel the warmth."
      }
    ]
  };

  final Map<String, List<Map<String, String>>> videos = {
    "Anxiety Relief": [
      {
        "title": "Calm Anxiety in 2 Minutes",
        "url": "https://www.youtube.com/watch?v=5zhnLG3GW-8"
      },
      {
        "title": "Quick Anxiety Reduction",
        "url": "https://www.youtube.com/watch?v=lrhPTqholcc"
      },
    ],
    "Breathing": [
      {
        "title": "Box Breathing Exercise",
        "url": "https://www.youtube.com/watch?v=tEmt1Znux58"
      },
      {
        "title": "Wim Hof Method Guide",
        "url": "https://www.youtube.com/watch?v=tybOi4hjZFQ"
      },
    ],
    "CBT Tools": [
      {
        "title": "What is CBT? (Overview)",
        "url": "https://www.youtube.com/watch?v=q6aAQgXauQw"
      },
      {
        "title": "Identify Cognitive Distortions",
        "url": "https://www.youtube.com/watch?v=aAVGyRMS3gE"
      },
      {
        "title": "How to Stop Rumination",
        "url": "https://www.youtube.com/watch?v=8GW_BfsDA38"
      },
    ],
    "Focus & Flow": [
      {
        "title": "Super Focus (40Hz Gamma)",
        "url": "https://www.youtube.com/watch?v=n4YghVcjbpw"
      },
      {
        "title": "Limitless Focus Beats",
        "url": "https://www.youtube.com/watch?v=tAIiXRZNh9E"
      },
      {
        "title": "Deep Focus for ADHD",
        "url": "https://www.youtube.com/watch?v=RG2IK8oRZNA"
      },
    ],
    "Somatic Release": [
      {
        "title": "Vagus Nerve Exercises",
        "url": "https://www.youtube.com/watch?v=eFV0FfMc_uo"
      },
    ],
    "Sleep Hygiene": [
      {
        "title": "NSDR Protocol (Deep Rest)",
        "url": "https://www.youtube.com/watch?v=AKGrmY8OSHM"
      },
      {
        "title": "Rain Sounds for Sleep",
        "url": "https://www.youtube.com/watch?v=mPZkdNFkNps"
      },
    ],
    "Gentle Yoga": [
      {
        "title": "Yoga for Mental Health",
        "url": "https://www.youtube.com/watch?v=COp7BR_Dvps"
      }
    ],
    "Guided Meditation": [
      {
        "title": "Mindfulness for Beginners",
        "url": "https://www.youtube.com/watch?v=ssss7V1_eyA"
      },
      {
        "title": "Letting Go of Overthinking",
        "url": "https://www.youtube.com/watch?v=1vx8iUvfyCY"
      },
    ],
  };

  final Map<String, List<String>> moodCategories = {
    "Anxious": [
      "Anxiety Relief",
      "Breathing",
      "Somatic Release",
      "Guided Meditation"
    ],
    "Low": [
      "CBT Tools",
      "Focus & Flow",
      "Gentle Yoga",
      "Guided Meditation"
    ],
    "Calm": [
      "Sleep Hygiene",
      "Breathing",
      "Guided Meditation",
      "Focus & Flow"
    ],
  };

  @override
  void initState() {
    super.initState();
    _applyAutoPersonalization();
    _loadFavoritesFromCloud();
  }

  void _applyAutoPersonalization() {
    if (anxietyScore > 15) {
      selectedMood = "Anxious";
    } else if (depressionScore > 15) {
      selectedMood = "Low";
    } else {
      selectedMood = "Calm";
    }
  }

  Future<void> _loadFavoritesFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      if (doc.exists && data != null && data.containsKey('favoriteVideos')) {
        final favList = List<String>.from(data['favoriteVideos']);
        setState(() => favorites = favList.toSet());
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

Future<void> _toggleFavorite(Map<String, String> video) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Extract data from the map
  final String url = video["url"] ?? "";
  final String title = video["title"] ?? "Untitled";
  final String videoId = YoutubePlayer.convertUrlToId(url) ?? "";
  
  if (url.isEmpty) return;

  // Create a unique document ID: UserID + VideoID
  final String docId = "${user.uid}_$videoId";
  final docRef = FirebaseFirestore.instance.collection('favorite_videos').doc(docId);

  try {
    if (favorites.contains(url)) {
      // 1. Remove from UI
      setState(() => favorites.remove(url));
      // 2. Remove from Firestore
      await docRef.delete();
    } else {
      // 1. Add to UI
      setState(() => favorites.add(url));
      // 2. Add to the new "favorite_videos" collection
      await docRef.set({
        'userId': user.uid,
        'videoId': videoId,
        'videoUrl': url,
        'title': title, // Adding title so the favorites tab can display it easily
        'moods': [selectedMood], 
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    debugPrint("Error toggling favorite: $e");
  }
}

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url,
        mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  void _playVideo(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) return;

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
        ),
      ),
    ).whenComplete(() => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF064E3B),
                  Color(0xFF020617),
                  Colors.black
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                Expanded(
                  child: currentTab == 0
                      ? _homeTab()
                      : _favoritesTab(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Remaining UI methods unchanged (cleaned formatting only)

  Widget _buildAppBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            "Guided Growth",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.import_contacts_rounded,
              color: Color(0xFF4ADE80),
              size: 26,
            ),
            onPressed: _showReadingNook,
          ),
        ],
      ),
    );
  }

  // ALL remaining UI methods stay logically identical
  // (kept exactly as your original, only formatted)

  // ---------- KEEPING REST SAME ----------

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true, fillColor: Colors.white.withOpacity(0.05),
          hintText: "Search practices...", hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4ADE80)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _homeTab() {
    final moodList = moodCategories[selectedMood] ?? [];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _moodSelector(),
        const SizedBox(height: 25),
        _buildClinicalInsight(),
        _buildTipsSection(),
        const SizedBox(height: 10),
        ...moodList.map((category) => _buildCategorySection(category)),
      ],
    );
  }

  Widget _buildClinicalInsight() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF4ADE80), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text("Tailored for your peace of mind", 
            style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _moodSelector() {
    final moods = {"Anxious": "🧘", "Low": "☁️", "Calm": "🌊"};
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: moods.entries.map((e) => GestureDetector(
          onTap: () => setState(() => selectedMood = e.key),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selectedMood == e.key ? const Color(0xFF4ADE80) : Colors.white.withOpacity(0.05), 
              borderRadius: BorderRadius.circular(15)
            ),
            child: Text("${e.value} ${e.key}", 
              style: TextStyle(color: selectedMood == e.key ? Colors.black : Colors.white70, fontWeight: FontWeight.w600)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = dailyTips[selectedMood] ?? dailyTips["Calm"]!;
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tips.length,
        itemBuilder: (context, index) => Container(
          width: 260, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03), 
            borderRadius: BorderRadius.circular(25), 
            border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.15))
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tips[index]['title']!, style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text(tips[index]['content']!, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    final list = (videos[category] ?? []).where((v) => v["title"]!.toLowerCase().contains(searchQuery)).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    
    String tag = (category == "CBT Tools" || category == "Somatic Release") ? "THERAPEUTIC" : "PRACTICE";

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 12), 
        child: Row(
          children: [
            Text(category, style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3)), borderRadius: BorderRadius.circular(4)),
              child: Text(tag, style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 7, fontWeight: FontWeight.w900)),
            )
          ],
        )
      ),
      ...list.map((v) => _videoTile(v)),
    ]);
  }

  Widget _videoTile(Map<String, String> video) {
    final isFav = favorites.contains(video["url"]);
    final String videoId = YoutubePlayer.convertUrlToId(video["url"]!) ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => _playVideo(video["url"]!),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network("https://img.youtube.com/vi/$videoId/mqdefault.jpg", width: 85, height: 50, fit: BoxFit.cover)
        ),
        title: Text(video["title"]!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: IconButton(icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white24), onPressed: () => _toggleFavorite(video)),
      ),
    );
  }

  Widget _favoritesTab() {
    final favVideos = videos.values.expand((e) => e).where((v) => favorites.contains(v["url"])).toList();
    if (favVideos.isEmpty) return const Center(child: Text("No favorites yet.", style: TextStyle(color: Colors.white24)));
    return ListView(padding: const EdgeInsets.all(24), children: favVideos.map((v) => _videoTile(v)).toList());
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: currentTab, backgroundColor: const Color(0xFF020617), selectedItemColor: const Color(0xFF4ADE80), unselectedItemColor: Colors.white24,
      onTap: (i) => setState(() => currentTab = i),
      items: const [BottomNavigationBarItem(icon: Icon(Icons.spa_outlined), label: "Explore"), BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Saved")],
    );
  }

  // --- READING NOOK MODAL ---
  void _showReadingNook() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF020617),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              const Text("Zen Library", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              ...practiceItems.map((item) => ListTile(
                onTap: () => _launchURL(item['url']!),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.self_improvement, color: Color(0xFF4ADE80)),
                title: Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(item['desc']!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              )),
              const Divider(color: Colors.white10, height: 40),
              ...curatedBooks.map((book) => ListTile(
                onTap: () => _launchURL(book['url']!),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.book, color: Color(0xFF4ADE80)),
                title: Text(book['title']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(book['author']!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              )),
            ],
          ),
        ),
      ),
    );
  }
}