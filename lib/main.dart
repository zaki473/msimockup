import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screen/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBQpCKRPOgQvcySuuhTJF7xp0pRz9OjB9M",
      appId: "1:570966993200:web:74a6be23f47d073cb240f5",
      messagingSenderId: "570966993200",
      projectId: "msimockup-c132d",
      storageBucket: "msimockup-c132d.firebasestorage.app",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Money Tracker Firebase',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}