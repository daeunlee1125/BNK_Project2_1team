import 'package:flutter/material.dart';
import 'package:test_main/voice/controller/voice_session_controller.dart';


class VoiceSessionScope extends InheritedWidget {
  final VoiceSessionController controller;

  const VoiceSessionScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static VoiceSessionController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<VoiceSessionScope>();
    assert(scope != null, 'VoiceSessionScope not found in widget tree');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(covariant VoiceSessionScope oldWidget) {
    return oldWidget.controller != controller;
  }
}