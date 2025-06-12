import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_screen.dart';



class TherapistProfileScreen extends StatefulWidget {
  const TherapistProfileScreen({super.key});

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  String? demographic;
  String? language;
  String? tone;
  String? focus;
  String? depth;

  final user = FirebaseAuth.instance.currentUser;

  Future<void> saveProfile() async {
    if (user != null && demographic != null && language != null && tone != null && focus != null && depth != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'therapistProfile': {
          'demographic': demographic,
          'language': language,
          'tone': tone,
          'focus': focus,
          'depth': depth,
        }
      }, SetOptions(merge: true));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Therapist Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ Demographics -----------------
            const Text('Demographics'),
            DropdownButton<String>(
              value: demographic,
              hint: const Text('Select'),
              onChanged: (value) => setState(() => demographic = value),
              items: [
                'Middle-aged female',
                'Young male',
                'Wise elder',
                'Spiritual guide',
                'Professional clinician'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
            // ------------------ Language Preference -----------------
            const Text('Language Preference'),
            DropdownButton<String>(
              value: language,
              hint: const Text('Select'),
              onChanged: (value) => setState(() => language = value),
              items: [
                'English',
                'Arabic'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
            // ------------------ Tone & Communication Style -----------------
            const Text('Tone & Communication Style'),
            DropdownButton<String>(
              value: tone,
              hint: const Text('Select'),
              onChanged: (value) => setState(() => tone = value),
              items: [
                'Compassionate',
                'Coaching',
                'Reflective Listener',
                'Humor + Warmth',
                'Direct & Honest'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
            // ------------------ Specialization Focus -----------------
            const Text('Specialization Focus'),
            DropdownButton<String>(
              value: focus,
              hint: const Text('Select'),
              onChanged: (value) => setState(() => focus = value),
              items: [
                'Conflict Resolution',
                'Emotional Support',
                'Growth & Goal-Setting',
                'Attachment Issues',
                'Communication Skills'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
            // ------------------ Depth Preference -----------------
            const Text('Depth Preference'),
            DropdownButton<String>(
              value: depth,
              hint: const Text('Select'),
              onChanged: (value) => setState(() => depth = value),
              items: [
                'Simple & Brief',
                'Medium Depth',
                'Deep Exploration'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (demographic != null && language != null && tone != null && focus != null && depth != null)
                  ? saveProfile
                  : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
