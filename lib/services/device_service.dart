
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  static const String _deviceIdKey = 'unique_device_id';

  Future<String> getDeviceID() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);

    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }
}
