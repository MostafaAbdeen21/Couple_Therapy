import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home/home_screen.dart';




class JoinPairingScreen extends StatefulWidget {
  const JoinPairingScreen({super.key});

  @override
  State<JoinPairingScreen> createState() => _JoinPairingScreenState();
}

class _JoinPairingScreenState extends State<JoinPairingScreen> {
  final _codeController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> joinWithCode(String code) async {
    final pairRef = FirebaseFirestore.instance.collection('pairs').doc(code);
    final doc = await pairRef.get();

    if (doc.exists && doc['userB'] == null && doc['userA'] != user!.uid) {
      await pairRef.update({
        'userB': user!.uid,
        'status': 'active',
      });

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'pairingId': code,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Partner connected successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } else if (doc['userA'] == user!.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot pair with yourself.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid or already used code.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Your Partner")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter the code your partner sent you:"),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(hintText: "Enter pairing code"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => joinWithCode(_codeController.text.trim()),
              child: const Text("Join Now"),
            )
          ],
        ),
      ),
    );
  }
}
