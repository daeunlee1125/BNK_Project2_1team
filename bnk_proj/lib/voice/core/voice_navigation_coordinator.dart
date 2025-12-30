import 'package:flutter/material.dart';
import 'package:test_main/screens/deposit/step_1.dart';
import 'package:test_main/screens/deposit/step_2.dart';
import 'package:test_main/screens/deposit/view.dart';
import 'package:test_main/voice/controller/voice_session_controller.dart';
import 'package:test_main/voice/ui/voice_nav_command.dart';

import '../../screens/deposit/signature.dart';

class VoiceNavigationCoordinator {
  final GlobalKey<NavigatorState> navigatorKey;
  final VoiceSessionController controller;

  VoiceNavigationCoordinator({
    required this.navigatorKey,
    required this.controller,
  }) {
    controller.navCommand.addListener(_handle);
  }

  void dispose() {
    controller.navCommand.removeListener(_handle);
  }

  void _handle() {
    final cmd = controller.navCommand.value;
    if (cmd == null) return;
    if (cmd.type == VoiceNavType.openSignature) {
      return; // ❗ null로 만들지 말고 그대로 둔다
    }

    controller.navCommand.value = null;

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (cmd.type) {
      case VoiceNavType.openDepositView:
        nav.pushNamed(
          DepositViewScreen.routeName,
          arguments: DepositViewArgs(dpstId: cmd.productCode!),
        );
        break;

      case VoiceNavType.openJoinFlow:
        nav.pushNamed(
          DepositStep1Screen.routeName,
          arguments: DepositStep1Args(dpstId: cmd.productCode!),
        );
        break;

      case VoiceNavType.openInput:
        nav.pushNamed(
          DepositStep2Screen.routeName,
          arguments: cmd.productCode
        );
        break;
      case VoiceNavType.openSignature:
        break;

      case VoiceNavType.openDepositList:
        throw UnimplementedError();
      case VoiceNavType.selectDepositTab:
        throw UnimplementedError();
    }
  }
}
