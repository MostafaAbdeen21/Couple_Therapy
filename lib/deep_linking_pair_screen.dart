// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:uni_links/uni_links.dart';
// import 'home_screen.dart';
//
// class DeepLinkPairingScreen extends StatefulWidget {
//   const DeepLinkPairingScreen({super.key});
//
//   @override
//   State<DeepLinkPairingScreen> createState() => _DeepLinkPairingScreenState();
// }
//
// class _DeepLinkPairingScreenState extends State<DeepLinkPairingScreen> {
//   final user = FirebaseAuth.instance.currentUser;
//   bool loading = true;
//   String? statusMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     handleIncomingLink();
//   }
//
//   void handleIncomingLink() async {
//     try {
//       final link = await getInitialLink();
//       if (link != null && link.contains('code=')) {
//         final pairingId = Uri.parse(link).queryParameters['code'];
//         if (pairingId != null) {
//           await attemptJoin(pairingId);
//         }
//       }
//     } catch (e) {
//       setState(() {
//         statusMessage = 'Error processing link.';
//         loading = false;
//       });
//     }
//   }
//
//   Future<void> attemptJoin(String pairingId) async {
//     final pairRef = FirebaseFirestore.instance.collection('pairs').doc(pairingId);
//     final doc = await pairRef.get();
//
//     if (doc.exists && doc['userB'] == null && user != null) {
//       await pairRef.update({
//         'userB': user!.uid,
//         'status': 'active',
//       });
//       await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
//         'pairingId': pairingId
//       }, SetOptions(merge: true));
//
//       setState(() {
//         statusMessage = 'Partner linked successfully!';
//         loading = false;
//       });
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//       );
//     } else {
//       setState(() {
//         statusMessage = 'Invalid or already used link.';
//         loading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Linking...')),
//       body: Center(
//         child: loading
//             ? const CircularProgressIndicator()
//             : Text(statusMessage ?? 'Something went wrong.'),
//       ),
//     );
//   }
// }
