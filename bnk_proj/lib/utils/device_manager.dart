/*
    기기 ID만 관리하는 클래스
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceManager {
  // 보안 저장소 인스턴스 생성
  static const _storage = FlutterSecureStorage();
  static const _keyDeviceId = 'secure_device_id';

  /// 기기 고유 ID 가져오기 (없으면 생성 후 저장)
  static Future<String> getDeviceId() async {
    // 1. 저장된 ID가 있는지 확인
    String? deviceId = await _storage.read(key: _keyDeviceId);

    // 2. 없으면 새로 생성 (최초 설치 시)
    if (deviceId == null) {
      deviceId = const Uuid().v4(); // 랜덤 UUID 생성

      // 3. 보안 저장소에 암호화하여 저장
      await _storage.write(key: _keyDeviceId, value: deviceId);
    }

    return deviceId;
  }
}

