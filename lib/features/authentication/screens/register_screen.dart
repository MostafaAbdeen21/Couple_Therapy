import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../error_screen.dart';
import 'OTP.dart';

class Registerscreen extends StatefulWidget {
  const Registerscreen({super.key});

  @override
  State<Registerscreen> createState() => _RegisterscreenState();
}

class _RegisterscreenState extends State<Registerscreen> {
  final _phoneController = TextEditingController();
  bool isLoading = false;

  void sendOtp() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty || !phone.startsWith('+')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter phone number with country code (e.g. +20...)'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          // التحقق التلقائي في حالة نجح
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => isLoading = false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ErrorDetailsScreen(
                errorTitle: "Verification Failed",
                errorDetails: 'Code: ${e.code}\nMessage: ${e.message}\nDetails: ${e.toString()}',
              ),
            ),
          );
        },


        codeSent: (String verificationId, int? resendToken) {
          setState(() => isLoading = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                verificationId: verificationId,
                phoneNumber: phone,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // بعد انتهاء وقت التحقق التلقائي
        },
        // forceResendingToken: null, // مش ضرورية دلوقتي
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Register With Your Number", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "e.g. +201234567890",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: sendOtp,
                child: const Text(
                  "Register",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}