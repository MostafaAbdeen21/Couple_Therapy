import 'package:couple_therapy_app/features/user/person_detail_screen.dart';
import 'package:couple_therapy_app/features/user/supscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../daily_journal_screen/screens/daily_journal_screen.dart';
import '../therapist/therapist_profile.dart';
import '../therapy_room_screen/therapy_room_screen.dart';
import 'additional_screen.dart';
import 'group_chat.dart';
import 'insightsscreen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isProfileComplete = false;
  bool isTherapistSelected = false;
  bool hasSubscription = false;
  bool hasUsedTrial = false;
  bool isStartingTrial = false;
  String? pairingId;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    checkProfileStatus();
  }

  Future<void> checkProfileStatus() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();

    if (data != null) {
      pairingId = data['pairingId'];
      setState(() {
        isProfileComplete = data.containsKey('profile');
        isTherapistSelected = data.containsKey('therapistProfile');
      });

      if (pairingId != null) {
        final pairDoc = await FirebaseFirestore.instance.collection('pairs').doc(pairingId).get();
        final pairData = pairDoc.data();
        final sub = pairData?['subscription'];

        if (sub != null) {
          final status = sub['status'];
          final trialEndsAt = (sub['trialEndsAt'] as Timestamp?)?.toDate();
          final now = DateTime.now();

          setState(() {
            hasUsedTrial = true;
            hasSubscription = status == 'active' ||
                (status == 'trial' && trialEndsAt != null && now.isBefore(trialEndsAt));
          });
        }
      }

    }
  }

  Future<void> startFreeTrial() async {
    if (pairingId == null) return;

    setState(() => isStartingTrial = true);

    try {
      final now = DateTime.now();
      final trialEnds = now.add(const Duration(days: 7));

      await FirebaseFirestore.instance.collection('pairs').doc(pairingId).update({
        'subscription': {
          'status': 'trial',
          'start': Timestamp.fromDate(now),
          'trialEndsAt': Timestamp.fromDate(trialEnds),
        }
      });

      setState(() {
        hasUsedTrial = true;
        hasSubscription = true;
        isStartingTrial = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Free trial started! Enjoy 7 days of full access")),
      );
    } catch (e) {
      setState(() => isStartingTrial = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to start trial: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Welcome to Couple Therapy App",
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (!isProfileComplete)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserPersonalDetailsScreen()));
                  },
                  icon: const Icon(Icons.person),
                  label: const Text("Complete Personal Profile"),
                ),

              if (!isTherapistSelected)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TherapistProfileScreen()));
                  },
                  icon: const Icon(Icons.favorite_outline),
                  label: const Text("Select Therapist Preferences"),
                ),

              if (isProfileComplete && isTherapistSelected) ...[
                ElevatedButton.icon(
                  onPressed: hasSubscription
                      ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DailyJournalScreen()));
                  }
                      : null,
                  icon: const Icon(Icons.book),
                  label: const Text("Daily Journal"),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: hasSubscription
                      ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TherapyRoomScreen(pairingId: pairingId)));
                  }
                      : null,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Therapy Room"),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: hasSubscription
                      ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(pairingId: pairingId)));
                  }
                      : null,
                  icon: const Icon(Icons.forum),
                  label: const Text("Group Chat"),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: hasSubscription
                      ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InsightsScreen(userid: user!.uid)));
                  }
                      : null,
                  icon: const Icon(Icons.bar_chart),
                  label: const Text("Insights & Progress"),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddOnsScreen()),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text("Buy More Journals & Sessions"),
                ),
                const SizedBox(height: 30),
                // ✅ زر الاشتراك لو مفيش اشتراك
                if (!hasSubscription)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                    },
                    icon: const Icon(Icons.star),
                    label: const Text("Subscribe Now to Unlock Full Access"),
                  ),
                if (!hasSubscription && !hasUsedTrial)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: isStartingTrial ? null : startFreeTrial,
                    icon: isStartingTrial
                        ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.card_giftcard),
                    label: isStartingTrial
                        ? const Text("Starting...")
                        : const Text("Start Free 7-Day Trial"),
                  ),


              ],
            ],
          ),
        ),
      ),
    );
  }
}
