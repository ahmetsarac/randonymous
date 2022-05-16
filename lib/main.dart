import 'package:flutter/material.dart';

void main() {
  runApp(const Randonymous());
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
      home: const Scaffold(
        body: Center(child: Text('Randonymous')),
      ),
    );
  }
}
