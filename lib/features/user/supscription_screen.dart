import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  Future<void> startCheckout(BuildContext context, String plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createCheckoutSession');
      final result = await callable.call({
        'plan': plan,
        'pairingId': await getPairingId(user.uid),
      });

      final url = result.data['url'];
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Redirecting to payment...")),
        );

        // فتح الرابط في المتصفح الخارجي
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create session: $e")),
      );
    }
  }

  Future<String?> getPairingId(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['pairingId'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upgrade Plan")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildPlanCard(context, "Monthly", "\$20 / month", "monthly"),
            buildPlanCard(context, "Quarterly", "\$54 / 3 months", "quarterly"),
            buildPlanCard(context, "Yearly", "\$168 / year", "yearly"),
          ],
        ),
      ),
    );
  }

  Widget buildPlanCard(BuildContext context, String title, String price, String planKey) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        subtitle: Text(price),
        trailing: ElevatedButton(
          onPressed: () => startCheckout(context, planKey),
          child: const Text("Subscribe"),
        ),
      ),
    );
  }
}
