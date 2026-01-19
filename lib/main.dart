import 'package:flutter/material.dart';
import 'Pages/Welcome_Page.dart';

void main() {
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