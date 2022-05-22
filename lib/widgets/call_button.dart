import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randonymous/providers/signaling_provider.dart';

class CallButton extends ConsumerWidget {
  const CallButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCalling = ref.watch(signalingProvider).isCalling;
    return Material(
      color: isCalling
          ? Theme.of(context).errorColor
          : Theme.of(context).primaryColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final signaling = ref.read(signalingProvider);
          if (signaling.permissionStatus == false) {
            await signaling.getMicrophoneAccess();
          }
          if (signaling.permissionStatus && signaling.isCalling == false) {
            signaling.makeCall();
          } else {
            signaling.hangUp();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Icon(
            isCalling ? Icons.call_end : Icons.call,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
