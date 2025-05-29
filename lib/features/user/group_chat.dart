import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupChatScreen extends StatelessWidget {
  final String? pairingId;

  const GroupChatScreen({super.key, required this.pairingId});

  @override
  Widget build(BuildContext context) {
    final groupChatRef = FirebaseFirestore.instance
        .collection('pairs')
        .doc(pairingId)
        .collection('groupChat')
        .orderBy('timestamp', descending: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Reflections")),
      body: StreamBuilder<QuerySnapshot>(
        stream: groupChatRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No messages yet."));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final data = messages[index].data() as Map<String, dynamic>;

              return Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(data['message'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
