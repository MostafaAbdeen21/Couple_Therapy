import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AddOnsScreen extends StatelessWidget {
  const AddOnsScreen({super.key});

  void _showAddonDialog(BuildContext context, String type) {
    final options = {
      'journal': {
        1: '\$1.99',
        5: '\$7.99',
        10: '\$14.99',
      },
      'session': {
        1: '\$4.99',
        3: '\$12.99',
        5: '\$19.99',
      },
    };

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options[type]!.entries.map((entry) {
              return ListTile(
                title: Text('${entry.key} ${type == 'journal' ? 'Journal(s)' : 'Session(s)'}'),
                subtitle: Text(entry.value),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _buyAddon(context, type, entry.key),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _buyAddon(BuildContext context, String type, int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final pairingId = doc.data()?['pairingId'];

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('buyAddOn');
      final result = await callable.call({
        'type': type,
        'quantity': quantity,
        'pairingId': pairingId,
      });

      final url = result.data['url'];
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirecting to Stripe...')),
        );
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buy Add-Ons")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.note_add),
              label: const Text("Buy Additional Journals"),
              onPressed: () => _showAddonDialog(context, 'journal'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_call),
              label: const Text("Buy Additional Sessions"),
              onPressed: () => _showAddonDialog(context, 'session'),
            ),
          ],
        ),
      ),
    );
  }
}
