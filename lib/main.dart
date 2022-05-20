import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randonymous/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: Randonymous()));
}

class Randonymous extends StatelessWidget {
  const Randonymous({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
