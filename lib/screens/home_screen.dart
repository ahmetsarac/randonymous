import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randonymous/widgets/call_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCalling = ref.watch(isCallingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randonymous'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CallButton(),
          SizedBox(
            height: 30,
            child: isCalling == true
                ? const Center(child: Text('Calling...'))
                : null,
          ),
        ],
      ),
    );
  }
}
