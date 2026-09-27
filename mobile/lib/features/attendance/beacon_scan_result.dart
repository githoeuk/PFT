class BeaconScanResult {
  const BeaconScanResult({
    required this.beaconUuid,
    required this.beaconMajor,
    required this.beaconMinor,
    required this.rssi,
    required this.deviceId,
  });

  final String beaconUuid;
  final int beaconMajor;
  final int beaconMinor;
  final int rssi;
  final String deviceId;

  Map<String, dynamic> toRequestBody() {
    return {
      'beaconUuid': beaconUuid,
      'beaconMajor': beaconMajor,
      'beaconMinor': beaconMinor,
      'rssi': rssi,
      'deviceId': deviceId,
    };
  }
}
