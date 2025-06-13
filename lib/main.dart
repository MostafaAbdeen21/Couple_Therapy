import 'package:couple_therapy_app/cubits/auth_cubit/auth_cubit.dart';
import 'package:couple_therapy_app/cubits/daily_journal_cubit/daily_journal_cubit.dart';
import 'package:couple_therapy_app/views/auth/register_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/supscription_cubit/supscription_cubit.dart';




void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    // لو عايز تشغل على iOS كمان، ضيف:
    appleProvider: AppleProvider.appAttest,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context)=>JournalCubit()),
          BlocProvider(create: (context)=>PhoneAuthCubit()),
          BlocProvider(create: (context)=>SubscriptionCubit()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Registerscreen() ,
        )
    );
  }
}
