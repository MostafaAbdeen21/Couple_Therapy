import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/register_screen.dart';
import '../paring/pairing_choice_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkUserStatus();
  }

  Future<void> checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    await Future.delayed(const Duration(seconds: 2));

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Registerscreen()),
      );
      return;
    }


    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final pairingId = doc.data()?['pairingId'];
    final pairDoc = await FirebaseFirestore.instance.collection('pairs').doc(pairingId).get();
    final pairData = pairDoc.data();
    final userB = pairData?['userB'];
    final status = pairData?['status'];

    if (pairingId != null && pairingId != '' && userB != null && status == 'active') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PairingChoiceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
