import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:couple_therapy_app/cubits/supscription_cubit/supscription_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit() : super(SubscriptionInitial());

  Future<void> startCheckout(String plan) async {
    emit(SubscriptionLoading());

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(SubscriptionError("User not logged in."));
      return;
    }

    try {
      final pairingId = await getPairingId(user.uid);
      if (pairingId == null) {
        emit(SubscriptionError("No pairing ID found."));
        return;
      }

      final callable = FirebaseFunctions.instance.httpsCallable('createCheckoutSession');
      final result = await callable.call({'plan': plan, 'pairingId': pairingId});
      final url = result.data['url'];

      emit(SubscriptionSuccess(url: url, pairingId: pairingId));
    } catch (e) {
      emit(SubscriptionError("Failed to start checkout: $e"));
    }
  }

  Future<String?> getPairingId(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['pairingId'];
  }

  Future<void> checkSubscriptionStatus(String pairingId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('pairs').doc(pairingId).get();
      final status = doc.data()?['subscription']?['status'];
      if (status == 'active') {
        emit(SubscriptionConfirmed());
      } else {
        emit(SubscriptionError("Payment not completed."));
      }
    } catch (e) {
      emit(SubscriptionError("Failed to verify subscription: $e"));
    }
  }
}
