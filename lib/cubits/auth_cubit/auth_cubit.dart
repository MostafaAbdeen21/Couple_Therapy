import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../views/home/splash_screen.dart';
import 'auth_state.dart';


class PhoneAuthCubit extends Cubit<PhoneAuthState> {
  PhoneAuthCubit() : super(PhoneAuthInitial());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String verificationId;

  void sendOtp(String phoneNumber, BuildContext context) async {
    if (phoneNumber.isEmpty || !phoneNumber.startsWith('+')) {
      emit(PhoneAuthError("Please enter a valid phone number with country code."));
      return;
    }

    emit(PhoneAuthLoading());

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      },

      verificationFailed: (FirebaseAuthException e) {
        emit(PhoneAuthError("Verification failed: ${e.message}"));
      },
      codeSent: (String verId, int? resendToken) {
        verificationId = verId;
        emit(PhoneAuthCodeSent());
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  void verifyOtp(String smsCode, BuildContext context) async {
    if (smsCode.length < 6) {
      emit(PhoneAuthError("Please enter the full 6-digit code."));
      return;
    }

    emit(PhoneAuthLoading());

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
      emit(PhoneAuthVerified());
    } catch (e) {
      emit(PhoneAuthError("Verification failed: $e"));
    }
  }
}
