import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../models/daily_journal_model.dart';
import 'daily_journal_state.dart';


class JournalCubit extends Cubit<JournalState> {
  JournalCubit() : super(JournalInitial());

  final user = FirebaseAuth.instance.currentUser;

  Future<void> fetchJournals() async {
    emit(JournalLoading());

    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final ref = FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("journals");

      final snap = await ref.orderBy("timestamp").get();

      List<JournalEntry> temp = [];
      bool alreadySubmitted = false;

      for (var doc in snap.docs) {
        final data = doc.data();
        final date = doc.id;

        if (date == today) {
          alreadySubmitted = true;
        }

        temp.add(JournalEntry(role: "user", text: data['message']));
        if (data['gptReply'] != null) {
          temp.add(JournalEntry(role: "gpt", text: data['gptReply']));
        }
      }

      // 👇 تحقق من extraJournals في pairs
      final pairSnap = await FirebaseFirestore.instance
          .collection("pairs")
          .where(Filter.or(
        Filter("userA", isEqualTo: user!.uid),
        Filter("userB", isEqualTo: user!.uid),
      ))
          .get();


      int extraJournals = 0;
      if (pairSnap.docs.isNotEmpty) {
        extraJournals = pairSnap.docs.first.data()['extraJournals'] ?? 0;
      }

      emit(JournalLoaded(
        messages: temp,
        alreadySubmitted: alreadySubmitted,
        hasExtraJournal: extraJournals > 0,
      ));
    } catch (e) {
      emit(JournalError("Failed to fetch journals: ${e.toString()}"));
    }
  }


  Future<void> submitJournal(String text) async {
    final currentState = state;
    if (currentState is JournalLoaded) {
      final alreadySubmitted = currentState.alreadySubmitted;
      final hasExtra = currentState.hasExtraJournal;
      if (text.trim().isEmpty || (alreadySubmitted && !hasExtra)) return;

      emit(JournalLoaded(
        messages: [...currentState.messages, JournalEntry(role: "user", text: text)],
        alreadySubmitted: true,
        hasExtraJournal: hasExtra,
      ));

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final journalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('journals')
          .doc(today);

      try {
        final existingDoc = await journalRef.get();
        if (existingDoc.exists && !hasExtra) return;

        final callable = FirebaseFunctions.instance.httpsCallable('generateGptReply');
        final result = await callable.call({"text": text});
        final gptReply = result.data['reply'];

        await journalRef.set({
          "message": text,
          "gptReply": gptReply,
          "timestamp": DateTime.now(),
        });

        // 👇 لو كتب جورنال زيادة، قلل واحدة من extraJournals
        if (alreadySubmitted && hasExtra) {
          final pairSnap = await FirebaseFirestore.instance
              .collection("pairs")
              .where(Filter.or(
            Filter("userA", isEqualTo: user!.uid),
            Filter("userB", isEqualTo: user!.uid),
          ))
              .get();


          if (pairSnap.docs.isNotEmpty) {
            final pairDoc = pairSnap.docs.first.reference;
            await pairDoc.update({
              "extraJournals": FieldValue.increment(-1),
            });
          }
        }

        emit(JournalLoaded(
          messages: [
            ...currentState.messages,
            JournalEntry(role: "user", text: text),
            JournalEntry(role: "gpt", text: gptReply),
          ],
          alreadySubmitted: true,
          hasExtraJournal: hasExtra && alreadySubmitted,
        ));
      } catch (e) {
        emit(JournalError("Failed to submit journal: ${e.toString()}"));
      }
    }
  }

}
