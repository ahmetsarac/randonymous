import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallingNotifier extends StateNotifier<bool> {
  CallingNotifier() : super(false);

  void changeCallingStatus() {
    state = !state;
  }
}

final isCallingProvider =
    StateNotifierProvider<CallingNotifier, bool>((ref) => CallingNotifier());
