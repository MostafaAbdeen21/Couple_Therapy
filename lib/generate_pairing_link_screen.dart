// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// class GeneratePairingLinkScreen extends StatefulWidget {
//   const GeneratePairingLinkScreen({super.key});
//
//   @override
//   State<GeneratePairingLinkScreen> createState() => _GeneratePairingLinkScreenState();
// }
//
// class _GeneratePairingLinkScreenState extends State<GeneratePairingLinkScreen> {
//   final user = FirebaseAuth.instance.currentUser;
//   String? pairingId;
//   String generatedLink="";
//
//   @override
//   void initState() {
//     super.initState();
//     generateOrFetchPairingId();
//   }
//
//   Future<void> generateOrFetchPairingId() async {
//     if (user == null) return;
//
//     final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
//     if (userDoc.exists && userDoc.data()!.containsKey('pairingId')) {
//       pairingId = userDoc['pairingId'];
//     } else {
//       pairingId = FirebaseFirestore.instance.collection('pairs').doc().id;
//       await FirebaseFirestore.instance.collection('pairs').doc(pairingId).set({
//         'userA': user!.uid,
//         'userB': null,
//         'status': 'pending',
//       });
//       await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
//         'pairingId': pairingId
//       }, SetOptions(merge: true));
//     }
//
//     generatedLink = 'coupletherapyapp://pair?code=$pairingId';
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Invite Your Partner")),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: pairingId == null
//             ? const Center(child: CircularProgressIndicator())
//             : Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text("Send this link to your partner to connect:"),
//             const SizedBox(height: 20),
//             SelectableText(
//               generatedLink,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(text: generatedLink));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Link copied!")),
//                 );
//               },
//               icon: const Icon(Icons.copy),
//               label: const Text("Copy Link"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
