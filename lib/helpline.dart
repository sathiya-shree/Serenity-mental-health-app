import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class Helpline extends StatefulWidget {
  const Helpline({super.key});

  @override
  State<Helpline> createState() => _HelplineState();
}

class _HelplineState extends State<Helpline> {
  String selectedState = "Pan India";
  String selectedLanguage = "All";

  final List<String> states = [
    "Pan India", "Andhra Pradesh", "Assam", "Bihar", "Delhi", "Gujarat", 
    "Karnataka", "Kerala", "Maharashtra", "Punjab", "Rajasthan", 
    "Tamil Nadu", "Telangana", "Uttar Pradesh", "West Bengal"
  ];
  
  final List<String> languages = [
    "All", "English", "Hindi", "Tamil", "Telugu", "Malayalam", 
    "Kannada", "Marathi", "Punjabi", "Gujarati", "Bengali"
  ];

  final List<HelplineModel> helplines = [
    HelplineModel(
        name: "Kiran (Govt. of India)", 
        phone: "1800-599-0019", 
        website: "https://www.mohfw.gov.in", 
        state: "Pan India", 
        languages: ["English", "Hindi"], 
        availability: "24x7 | Free", 
        emergency: true, 
        isGovt: true),
    HelplineModel(
        name: "Sneha Foundation", 
        phone: "044-24640050", 
        website: "https://snehaindia.org", 
        state: "Tamil Nadu", 
        languages: ["Tamil", "English"], 
        availability: "24x7", 
        emergency: true, 
        isGovt: false),
    HelplineModel(
        name: "Aasra", 
        phone: "09820466726", 
        website: "https://aasra.info", 
        state: "Maharashtra", 
        languages: ["English", "Hindi", "Marathi"], 
        availability: "24x7", 
        emergency: true, 
        isGovt: false),
    HelplineModel(
        name: "DISHA – Kerala Govt", 
        phone: "1056", 
        website: "https://disha.kerala.gov.in", 
        state: "Kerala", 
        languages: ["Malayalam", "English"], 
        availability: "24x7", 
        emergency: true, 
        isGovt: true),
    HelplineModel(
        name: "Vandrevala Foundation", 
        phone: "9999-666-555", 
        website: "https://vandrevalafoundation.com", 
        state: "Pan India", 
        languages: ["English", "Hindi"], 
        availability: "24x7", 
        emergency: true, 
        isGovt: false),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHelplines();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF020617)],
          ),
        ),
        child: Stack(
          children: [
            _buildAmbientDecor(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomAppBar(),
                    const SizedBox(height: 15),
                    
                    // --- HEADER & DESCRIPTION ---
                    const Text(
                      "Emergency Support 🌿",
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Who are they?",
                            style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "These are certified professional counselors and government-led crisis teams. They provide immediate, confidential support for emotional distress, suicidal thoughts, or mental health emergencies. While Dawn is here to listen, these services provide human-to-human intervention when you need it most.",
                            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildFilters(),
                    const SizedBox(height: 20),
                    
                    Expanded(
                      child: filtered.isEmpty
                          ? _noResultsUI()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _helplineCard(filtered[i]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text("Guidance & Support", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(child: _glassDropdown(states, selectedState, (v) => setState(() => selectedState = v))),
        const SizedBox(width: 12),
        Expanded(child: _glassDropdown(languages, selectedLanguage, (v) => setState(() => selectedLanguage = v))),
      ],
    );
  }

  Widget _glassDropdown(List<String> items, String value, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF0F172A),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4ADE80)),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Widget _helplineCard(HelplineModel h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: h.emergency ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: h.emergency ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF4ADE80).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(h.emergency ? Icons.emergency : Icons.support_agent, 
                        color: h.emergency ? Colors.redAccent : const Color(0xFF4ADE80), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(h.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                              if (h.isGovt) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified, color: Colors.blue, size: 16)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(h.availability, style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(h.languages.join(", "), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _actionBtn(Icons.phone, "Call", Colors.green, () => FlutterPhoneDirectCaller.callNumber(h.phone)),
                    _actionBtn(Icons.copy, "Copy", Colors.orange, () {
                      Clipboard.setData(ClipboardData(text: h.phone));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Number Copied")));
                    }),
                    _actionBtn(Icons.public, "Visit", Colors.blue, () => launchUrl(Uri.parse(h.website))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientDecor() {
    return Positioned(
      top: 100, right: -50,
      child: Container(
        width: 200, height: 200,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4ADE80).withOpacity(0.05)),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)),
      ),
    );
  }

  List<HelplineModel> _filteredHelplines() {
    final matches = helplines.where((h) {
      final stateMatch = selectedState == "Pan India" || h.state == selectedState || h.state == "Pan India";
      final langMatch = selectedLanguage == "All" || h.languages.contains(selectedLanguage);
      return stateMatch && langMatch;
    }).toList();
    matches.sort((a, b) => b.emergency ? 1 : -1);
    return matches;
  }

  Widget _noResultsUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No local helplines found", style: TextStyle(color: Colors.white70)),
          TextButton(onPressed: () => setState(() => selectedState = "Pan India"), child: const Text("Show Pan-India Support", style: TextStyle(color: Color(0xFF4ADE80)))),
        ],
      ),
    );
  }
}

class HelplineModel {
  final String name;
  final String phone;
  final String website;
  final String state;
  final List<String> languages;
  final String availability;
  final bool emergency;
  final bool isGovt;

  HelplineModel({
    required this.name, required this.phone, required this.website, 
    required this.state, required this.languages, required this.availability, 
    required this.emergency, required this.isGovt
  });
}