import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isCallingProvider = StateProvider<bool>((ref) {
  return false;
});

class CallButton extends ConsumerWidget {
  const CallButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCalling = ref.watch(isCallingProvider);
    return Material(
      color: isCalling
          ? Theme.of(context).errorColor
          : Theme.of(context).primaryColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          Future.delayed(
              const Duration(seconds: 1),
              () => ref
                  .read(isCallingProvider.notifier)
                  .update((state) => !state));
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
