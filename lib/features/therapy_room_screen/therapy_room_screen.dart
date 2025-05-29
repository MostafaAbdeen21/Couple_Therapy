import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TherapyRoomScreen extends StatefulWidget {
  final String? pairingId;

  const TherapyRoomScreen({super.key, required this.pairingId});

  @override
  State<TherapyRoomScreen> createState() => _TherapyRoomScreenState();
}

class _TherapyRoomScreenState extends State<TherapyRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  String? partnerId;
  bool isPartnerOnline = false;
  bool sessionAvailable = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPartnerId();
    checkSessionAvailability();
    markPresence(true);
  }

  @override
  void dispose() {
    markPresence(false);
    super.dispose();
  }

  Future<void> markPresence(bool online) async {
    await FirebaseFirestore.instance
        .collection('pairs')
        .doc(widget.pairingId)
        .collection('presence')
        .doc(userId)
        .set({'online': online});
  }

  Future<void> loadPartnerId() async {
    final pairDoc = await FirebaseFirestore.instance
        .collection('pairs')
        .doc(widget.pairingId)
        .get();

    final data = pairDoc.data()!;
    final userA = data['userA'];
    final userB = data['userB'];

    partnerId = userId == userA ? userB : userA;

    FirebaseFirestore.instance
        .collection('pairs')
        .doc(widget.pairingId)
        .collection('presence')
        .doc(partnerId)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        isPartnerOnline = snapshot.data()?['online'] == true;
      });
    });
  }

  Future<void> checkSessionAvailability() async {
    final pairDoc = await FirebaseFirestore.instance
        .collection('pairs')
        .doc(widget.pairingId)
        .get();

    final lastSession = pairDoc.data()?['lastSessionTimestamp']?.toDate();
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    setState(() {
      sessionAvailable = lastSession == null || lastSession.isBefore(startOfWeek);
      loading = false;
    });
  }

  Future<void> sendMessage() async {
    if (!isPartnerOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your partner is not online yet.')),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatRef = FirebaseFirestore.instance
        .collection('pairs')
        .doc(widget.pairingId)
        .collection('therapyRoom');

    await chatRef.add({
      'userId': userId,
      'message': message,
      'type': 'user',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();

    try {
      final snapshot = await chatRef.orderBy('timestamp', descending: false).get();
      final history = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'role': data['userId'] == 'gpt' ? 'assistant' : 'user',
          'content': data['message'],
        };
      }).toList();

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('gptTherapyReply');
      final result = await callable.call(<String, dynamic>{
        'pairingId': widget.pairingId,
        'history': history,
      });

      final gptReply = result.data['reply'] as String;

      await chatRef.add({
        'userId': 'gpt',
        'message': gptReply,
        'type': 'gpt',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error getting GPT reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get AI response.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final therapyRoomRef = FirebaseFirestore.instance
        .collection('pairs')
        .doc(widget.pairingId)
        .collection('therapyRoom')
        .orderBy('timestamp', descending: false);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!sessionAvailable) {
      return Scaffold(
        appBar: AppBar(title: const Text("Therapy Room")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "✅ You’ve already completed this week’s session.\nCome back next week!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Therapy Room")),
      body: partnerId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (!isPartnerOnline)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Waiting for your partner to join..."),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: therapyRoomRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['userId'] == userId;
                    final isGPT = data['userId'] == 'gpt';
                    final alignment = isGPT ? Alignment.center : (isMe ? Alignment.centerRight : Alignment.centerLeft);

                    return Align(
                      alignment: alignment,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isGPT
                              ? Colors.grey[300]
                              : isMe
                              ? Colors.blue[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(data['message'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: isPartnerOnline,
                    decoration: const InputDecoration(hintText: "Type your message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: isPartnerOnline ? sendMessage : null,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
