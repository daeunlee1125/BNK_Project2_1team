import 'package:flutter/widgets.dart';
import 'package:test_main/voice/core/voice_overlay_mode.dart';
import '../ui/voice_assistant_overlay.dart';
import '../controller/voice_session_controller.dart';

class VoiceOverlayManager {
  static OverlayEntry? _entry;
  static VoiceOverlayMode _mode = VoiceOverlayMode.expanded;

  static VoiceOverlayMode get mode => _mode;

  static void show(BuildContext context, VoiceSessionController controller) {
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (_) => VoiceAssistantOverlay(
        controller: controller,
        mode: _mode,
        onModeChanged: _setMode,
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void _setMode(VoiceOverlayMode mode) {
    _mode = mode;
    _entry?.markNeedsBuild();
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
    _mode = VoiceOverlayMode.hidden;
  }

  static void endSession(VoiceSessionController controller) {
    controller.endSession();
    hide();
  }
}
