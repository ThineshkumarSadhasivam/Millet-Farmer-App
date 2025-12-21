import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Screens
import 'buyer_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android reads config from google-services.json
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BuyerHomeScreen(), // ✅ Buyer starts here
    );
  }
}
