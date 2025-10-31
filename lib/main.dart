import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hotelapp/firebase_options.dart';
import 'package:hotelapp/screens/page01/login_page.dart';
import 'package:hotelapp/screens/page02/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {'home': (context) => home_page()},
    );
  }
}
