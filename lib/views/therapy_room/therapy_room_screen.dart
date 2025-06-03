import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/therapy_room_cubit/therapy_room_cubit.dart';
import '../../cubits/therapy_room_cubit/therapy_room_state.dart';


class TherapyRoomScreen extends StatelessWidget {
  final String? pairingId;
  final TextEditingController _controller = TextEditingController();

  TherapyRoomScreen({super.key, required this.pairingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TherapyRoomCubit(pairingId: pairingId)..markPresence(true),
      child: BlocBuilder<TherapyRoomCubit, TherapyRoomState>(
        builder: (context, state) {
          if (state is TherapyRoomLoading || state is TherapyRoomInitial) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (state is TherapyRoomError) {
            return Scaffold(body: Center(child: Text('Error: ${state.error}')));
          }

          final cubit = context.read<TherapyRoomCubit>();
          final isAvailable = (state as TherapyRoomLoaded).sessionAvailable;
          final isPartnerOnline = state.isPartnerOnline;

          return Scaffold(
            appBar: AppBar(title: const Text("Therapy Room")),
            body: Column(
              children: [
                if (!isPartnerOnline)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text("Waiting for your partner to join..."),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final alignment = msg.userId == 'gpt'
                          ? Alignment.center
                          : (msg.userId == cubit.userId ? Alignment.centerRight : Alignment.centerLeft);

                      return Align(
                        alignment: alignment,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: msg.userId == 'gpt'
                                ? Colors.grey[300]
                                : (msg.userId == cubit.userId ? Colors.blue[100] : Colors.green[100]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(msg.message),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                if (isAvailable)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: isPartnerOnline,
                            decoration: const InputDecoration(hintText: "Type your message..."),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: isPartnerOnline
                              ? () {
                            final text = _controller.text;
                            _controller.clear();
                            cubit.sendMessage(text);
                          }
                              : null,
                        )
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("✅ You’ve already completed this week’s session.\nCome back next week!",
                        textAlign: TextAlign.center),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}