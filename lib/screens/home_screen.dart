import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randonymous/providers/calling_provider.dart';
import 'package:randonymous/providers/signaling_provider.dart';
import 'package:randonymous/widgets/call_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(signalingProvider).localRenderer.initialize();
    ref.read(signalingProvider).remoteRenderer.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    ref.read(signalingProvider).localRenderer.dispose();
    ref.read(signalingProvider).remoteRenderer.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
