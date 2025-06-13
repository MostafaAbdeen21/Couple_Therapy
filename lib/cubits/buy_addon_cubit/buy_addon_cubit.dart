import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'buy_addon_state.dart';

class BuyAddonCubit extends Cubit<BuyAddonState> {
  BuyAddonCubit() : super(BuyAddonInitial());

  Future<void> buyAddon({required String type, required int quantity}) async {
    emit(BuyAddonLoading());

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(BuyAddonError("User not logged in."));
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final pairingId = doc.data()?['pairingId'];

      final callable = FirebaseFunctions.instance.httpsCallable('buyAddOn-buyAddOn');
      final result = await callable.call({
        'type': type,
        'quantity': quantity,
        'pairingId': pairingId,
      });

      final url = result.data['url'];
      if (url != null) {
        emit(BuyAddonSuccess(url));
      } else {
        emit(BuyAddonError("URL not found."));
      }
    } catch (e) {
      emit(BuyAddonError(e.toString()));
    }
  }
}
