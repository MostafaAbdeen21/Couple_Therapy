import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../user/home_screen.dart';

class SharePairingCodeScreen extends StatefulWidget {
  const SharePairingCodeScreen({super.key});

  @override
  State<SharePairingCodeScreen> createState() => _SharePairingCodeScreenState();
}

class _SharePairingCodeScreenState extends State<SharePairingCodeScreen> {
  String pairingId = "";
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    generatePairingCode();
  }

  Future<void> generatePairingCode() async {
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

    // ✅ لو عنده pairingId بالفعل
    if (userDoc.exists && userDoc.data()!.containsKey('pairingId')) {
      pairingId = userDoc['pairingId'];
      setState(() {});
      return;
    }

    // ✅ تحقق هل المستخدم موجود بالفعل كـ userB في أي pairing
    final query = await FirebaseFirestore.instance
        .collection('pairs')
        .where('userB', isEqualTo: user!.uid)
        .get();

    if (query.docs.isNotEmpty) {
      // ✅ موجود بالفعل كـ userB → خزن pairingId بتاعه
      pairingId = query.docs.first.id;

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'pairingId': pairingId,
      }, SetOptions(merge: true));

      setState(() {});
      return;
    }

    // ✅ مش موجود خالص → أنشئ pairing جديد كـ userA
    pairingId = FirebaseFirestore.instance.collection('pairs').doc().id;

    await FirebaseFirestore.instance.collection('pairs').doc(pairingId).set({
      'userA': user!.uid,
      'userB': null,
      'status': 'pending',
    });

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'pairingId': pairingId,
    }, SetOptions(merge: true));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (pairingId == "") {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('pairs').doc(pairingId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(
            body: Center(child: Text("Error loading pairing data")),
          );
        }

        // لو الربط اكتمل
        if (data['status'] == 'active' && data['userB'] != null) {
          // ننقل للـ HomeScreen تلقائي
          Future.microtask(() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ),
            );
          });
          return const Scaffold(
            body: Center(child: Text("Partner connected! Redirecting...")),
          );
        }

        // لو لسه شريك مش متصل
        return Scaffold(
          appBar: AppBar(title: const Text("Your Pairing Code")),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Send this code to your partner to link accounts:"),
                const SizedBox(height: 20),
                SelectableText(pairingId, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: pairingId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Code copied!")),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy Code"),
                ),
                const SizedBox(height: 30),
                const Text("Waiting for partner to join..."),
              ],
            ),
          ),
        );
      },
    );
  }
}
