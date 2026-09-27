import 'beacon_scan_result.dart';

class BeaconScannerService {
  const BeaconScannerService();

  Future<BeaconScanResult> findNearestBeacon() async {
    return const BeaconScanResult(
      beaconUuid: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
      beaconMajor: 101,
      beaconMinor: 1,
      rssi: -60,
      deviceId: 'test-device-001',
    );
  }
}
