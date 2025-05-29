import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  bool alreadySubmitted = false;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    fetchJournals();
  }

  Future<void> fetchJournals() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("journals");

    final snap = await ref.orderBy("timestamp").get();

    List<Map<String, dynamic>> temp = [];
    for (var doc in snap.docs) {
      final data = doc.data();
      final date = doc.id;
      if (date == today) {
        alreadySubmitted = true;
      }
      temp.add({"role": "user", "text": data['message']});
      if (data['gptReply'] != null) {
        temp.add({"role": "gpt", "text": data['gptReply']});
      }
    }

    setState(() {
      messages = temp;
    });

    _scrollToBottom(); // Scroll after loading messages
  }

  Future<void> submitJournal() async {
    if (_controller.text.trim().isEmpty || alreadySubmitted) return;

    final text = _controller.text.trim();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final journalRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('journals')
        .doc(today);

    setState(() {
      isLoading = true;
      messages.add({"role": "user", "text": text});
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateGptReply');
      final result = await callable.call({"text": text});

      final gptReply = result.data['reply'];

      await journalRef.set({
        "message": text,
        "gptReply": gptReply,
        "timestamp": DateTime.now(),
      });

      setState(() {
        messages.add({"role": "gpt", "text": gptReply});
        alreadySubmitted = true;
        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget buildMessageBubble(String text, String role) {
    final isUser = role == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Daily Journal Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("GPT is typing..."),
                    ),
                  );
                }
                final msg = messages[index];
                return buildMessageBubble(msg['text'], msg['role']);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: alreadySubmitted
                ? const Align(
              alignment: Alignment.center,
              child: Text(
                '✅ You already submitted your journal today.',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            )
                : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Write how you feel today...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: submitJournal,
                  child: const Text("Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
