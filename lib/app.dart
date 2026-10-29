import 'package:flutter/material.dart';

class MigaApp extends StatelessWidget {
  const MigaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E72)),
      ),
      home: const Scaffold(body: Center(child: Text('Miga'))),
    );
  }
}
