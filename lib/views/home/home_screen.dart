import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/home_cubit/home_cubit.dart';
import '../../cubits/home_cubit/home_state.dart';
import '../daily_journal_screen/screens/daily_journal_screen.dart';
import '../therapist/therapist_profile.dart';
import '../therapy_room/therapy_room_screen.dart';
import '../user/additional_screen.dart';
import '../user/group_chat.dart';
import '../user/insightsscreen.dart';
import '../user/person_detail_screen.dart';
import 'supscription_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..checkProfileStatus(),
      child: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeLoaded) {
            return Scaffold(
              appBar: AppBar(title: const Text("Home")),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Welcome to Couple Therapy App", textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 40),
                    if (!state.isProfileComplete)
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => UserPersonalDetailsScreen())),
                        icon: const Icon(Icons.person),
                        label: const Text("Complete Personal Profile"),
                      ),
                    if (!state.isTherapistSelected)
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => TherapistProfileScreen())),
                        icon: const Icon(Icons.favorite_outline),
                        label: const Text("Select Therapist Preferences"),
                      ),
                    if (state.isProfileComplete && state.isTherapistSelected) ...[
                      ElevatedButton.icon(
                        onPressed: state.hasSubscription ? () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => DailyJournalScreen())) : null,
                        icon: const Icon(Icons.book),
                        label: const Text("Daily Journal"),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: state.hasSubscription ? () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => TherapyRoomScreen(pairingId: state.pairingId))) : null,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("Therapy Room"),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: state.hasSubscription ? () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => GroupChatScreen(pairingId: state.pairingId))) : null,
                        icon: const Icon(Icons.forum),
                        label: const Text("Group Chat"),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: state.hasSubscription ? () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => InsightsScreen(userid: FirebaseAuth.instance.currentUser!.uid))) : null,
                        icon: const Icon(Icons.bar_chart),
                        label: const Text("Insights & Progress"),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const AddOnsScreen())),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text("Buy More Journals & Sessions"),
                      ),
                      const SizedBox(height: 30),
                      if (!state.hasSubscription)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen())),
                          icon: const Icon(Icons.star),
                          label: const Text("Subscribe Now to Unlock Full Access"),
                        ),
                      if (!state.hasSubscription && !state.hasUsedTrial)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: state.isStartingTrial ? null
                              : () => context.read<HomeCubit>().startFreeTrial(),
                          icon: state.isStartingTrial ?
                          const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) :
                          const Icon(Icons.card_giftcard),
                          label: state.isStartingTrial ? const Text("Starting...")
                              : const Text("Start Free 7-Day Trial"),
                        ),
                    ]
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text("Something went wrong."));
          }
        },
      ),
    );
  }
}