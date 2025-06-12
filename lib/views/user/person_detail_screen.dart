import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_screen.dart';

class UserPersonalDetailsScreen extends StatefulWidget {
  const UserPersonalDetailsScreen({super.key});

  @override
  State<UserPersonalDetailsScreen> createState() => _UserPersonalDetailsScreenState();
}

class _UserPersonalDetailsScreenState extends State<UserPersonalDetailsScreen> {
  final _firstNameController = TextEditingController();

  String? ageGroup;
  String? gender;
  String? relationshipLength;
  String? therapyStyle;
  String? language;

  List<String> challenges = [];
  List<String> challengeOptions = [
    'Communication',
    'Trust',
    'Distance',
    'Conflict',
    'Emotional Expression'
  ];

  final user = FirebaseAuth.instance.currentUser;

  Future<void> saveProfile() async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'profile': {
          'firstName': _firstNameController.text.trim(),
          'ageGroup': ageGroup,
          'gender': gender,
          'relationshipLength': relationshipLength,
          'challenges': challenges,
          'therapyStyle': therapyStyle,
          'language': language,
        }
      }, SetOptions(merge: true));

      // Navigate forward (replace with your route)
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Personal Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name (optional)'),
            ),
            const SizedBox(height: 12),
            _buildDropdown('Age Group', ageGroup, [
              '18–24', '25–34', '35–44', '45–54', '55+'
            ], (val) => setState(() => ageGroup = val)),
            _buildDropdown('Gender', gender, [
              'Male', 'Female', 'Other', 'Prefer not to say'
            ], (val) => setState(() => gender = val)),
            _buildDropdown('Relationship Length', relationshipLength, [
              '0–6 months', '6m–2y', '2–5y', '5y+'
            ], (val) => setState(() => relationshipLength = val)),
            const SizedBox(height: 16),
            const Text('Biggest Relationship Challenges'),
            ...challengeOptions.map((option) => CheckboxListTile(
              title: Text(option),
              value: challenges.contains(option),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    challenges.add(option);
                  } else {
                    challenges.remove(option);
                  }
                });
              },
            )),
            _buildDropdown('Preferred Therapy Style', therapyStyle, [
              'Gentle', 'Direct', 'Coaching', 'Reflective'
            ], (val) => setState(() => therapyStyle = val)),
            _buildDropdown('Language Preference', language, [
              'Simple English', 'Fluent English', 'Arabic'
            ], (val) => setState(() => language = val)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: const Text('Select'),
          onChanged: onChanged,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
