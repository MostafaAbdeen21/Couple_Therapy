import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/home_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  final user = FirebaseAuth.instance.currentUser;
  String? pairingId;

  Future<void> checkProfileStatus() async {
    emit(HomeLoading());

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final data = doc.data();

      bool isProfileComplete = false;
      bool isTherapistSelected = false;
      bool hasSubscription = false;
      bool hasUsedTrial = false;

      if (data != null) {
        pairingId = data['pairingId'];
        isProfileComplete = data.containsKey('profile');
        isTherapistSelected = data.containsKey('therapistProfile');

        if (pairingId != null) {
          final pairDoc = await FirebaseFirestore.instance.collection('pairs').doc(pairingId).get();
          final pairData = pairDoc.data();
          final sub = pairData?['subscription'];

          if (sub != null) {
            final model = SubscriptionModel.fromMap(sub);
            final now = DateTime.now();
            hasUsedTrial = true;
            hasSubscription = model.status == 'active' ||
                (model.status == 'trial' && model.trialEndsAt != null && now.isBefore(model.trialEndsAt!));
          }
        }
      }

      emit(HomeLoaded(
        isProfileComplete: isProfileComplete,
        isTherapistSelected: isTherapistSelected,
        hasSubscription: hasSubscription,
        hasUsedTrial: hasUsedTrial,
        isStartingTrial: false,
        pairingId: pairingId,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> startFreeTrial() async {
    if (pairingId == null) return;

    final currentState = state;
    if (currentState is! HomeLoaded) return;

    emit(currentState.copyWith(isStartingTrial: true));

    try {
      final now = DateTime.now();
      final trialEnds = now.add(const Duration(days: 7));

      await FirebaseFirestore.instance.collection('pairs').doc(pairingId).update({
        'subscription': {
          'status': 'trial',
          'start': Timestamp.fromDate(now),
          'trialEndsAt': Timestamp.fromDate(trialEnds),
        },
      });

      emit(currentState.copyWith(
        hasUsedTrial: true,
        hasSubscription: true,
        isStartingTrial: false,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}