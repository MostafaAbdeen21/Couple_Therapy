import 'package:couple_therapy_app/views/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../cubits/supscription_cubit/supscription_cubit.dart';
import '../../cubits/supscription_cubit/supscription_state.dart';


class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  void _startSubscription(BuildContext context, String plan) {
    context.read<SubscriptionCubit>().startCheckout(plan);
  }

  Widget buildPlanCard(BuildContext context, String title, String price, String plan) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(price),
        trailing: ElevatedButton(
          onPressed: () => _startSubscription(context, plan),
          child: const Text("Subscribe"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (context, state) async {
        if (state is SubscriptionLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        } else {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading
        }

        if (state is SubscriptionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🔄 Redirecting to payment...")),
          );

          // فتح صفحة الدفع
          await launchUrl(Uri.parse(state.url), mode: LaunchMode.externalApplication);

          // التحقق من الاشتراك بعد 8 ثواني
          Future.delayed(const Duration(seconds: 8), () {
            context.read<SubscriptionCubit>().checkSubscriptionStatus(state.pairingId);
          });
        }

        if (state is SubscriptionConfirmed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Subscription successful!")),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context)=>HomeScreen()));
        }

        if (state is SubscriptionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ ${state.message}")),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text("Choose Your Plan")),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              buildPlanCard(context, "Monthly Plan", "\$20 / month", "monthly"),
              buildPlanCard(context, "Quarterly Plan", "\$50 / 3 months", "quarterly"),
              buildPlanCard(context, "Yearly Plan", "\$180 / year", "yearly"),
            ],
          ),
        );
      },
    );
  }
}
