import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Pages/Welcome_Page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RoomReserveApp());
}

class RoomReserveApp extends StatelessWidget {
  const RoomReserveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoomReserve',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // change from purple
        ),
      ),
      home: const WelcomePage(),
    );
  }
}