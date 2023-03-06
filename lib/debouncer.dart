///
/// Author: @m-f-1998
/// Description: Delay Searches for 'x' Seconds e.g. Preventing too many Network Requests
/// Framework: https://flutter.dev
///

import 'dart:async';
import 'package:flutter/material.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
