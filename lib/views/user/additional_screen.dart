import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../cubits/buy_addon_cubit/buy_addon_cubit.dart';
import '../../cubits/buy_addon_cubit/buy_addon_state.dart';

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
                onTap: () {
                  Navigator.pop(context);
                  context.read<BuyAddonCubit>().buyAddon(type: type, quantity: entry.key);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _handleState(BuildContext context, BuyAddonState state) async {
    if (state is BuyAddonSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redirecting to Stripe...')),
      );
      await launchUrl(Uri.parse(state.url), mode: LaunchMode.externalApplication);
    } else if (state is BuyAddonError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BuyAddonCubit(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Buy Add-Ons")),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocConsumer<BuyAddonCubit, BuyAddonState>(
            listener: _handleState,
            builder: (context, state) {
              return Column(
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
                  const SizedBox(height: 40),
                  if (state is BuyAddonLoading)
                    const CircularProgressIndicator()
                  else
                    const SizedBox.shrink(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
