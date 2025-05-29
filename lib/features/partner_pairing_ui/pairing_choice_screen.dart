import 'package:couple_therapy_app/features/partner_pairing_ui/share_pairing_screen.dart';
import 'package:flutter/material.dart';

import 'enter_code_screen.dart';

class PairingChoiceScreen extends StatelessWidget {
  const PairingChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connect with your partner")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "How do you want to connect?",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text("Create and share code"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context)=> const SharePairingCodeScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.key),
              label: const Text("I have a code"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context)=> const JoinPairingScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
