import 'dart:async';
import 'dart:io';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart' as beacon;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'beacon_scan_result.dart';

class BeaconScannerService {
  const BeaconScannerService({
    this.scanTimeout = const Duration(seconds: 5),
    this.iBeaconUuid = const String.fromEnvironment(
      'IBEACON_UUID',
      defaultValue: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
    ),
  });

  final Duration scanTimeout;
  final String iBeaconUuid;

  Future<BeaconScanResult> findNearestBeacon() async {
    await _prepareScanning();

    final regions = _scanRegions();
    final detectedBeacons = <beacon.Beacon>[];
    final completer = Completer<List<beacon.Beacon>>();
    StreamSubscription<beacon.RangingResult>? subscription;

    try {
      subscription = beacon.flutterBeacon
          .ranging(regions)
          .listen(
            (result) {
              detectedBeacons.addAll(result.beacons);

              if (detectedBeacons.isNotEmpty && !completer.isCompleted) {
                completer.complete(List<beacon.Beacon>.of(detectedBeacons));
              }
            },
            onError: (Object error) {
              if (!completer.isCompleted) {
                completer.completeError(error);
              }
            },
          );

      final beacons = await completer.future.timeout(
        scanTimeout,
        onTimeout: () => List<beacon.Beacon>.of(detectedBeacons),
      );

      if (beacons.isEmpty) {
        throw StateError('출석 가능한 비콘을 찾지 못했습니다. 비콘 근처에서 다시 시도해주세요.');
      }

      beacons.sort((a, b) => b.rssi.compareTo(a.rssi));
      final nearest = beacons.first;

      return BeaconScanResult(
        beaconUuid: nearest.proximityUUID,
        beaconMajor: nearest.major,
        beaconMinor: nearest.minor,
        rssi: nearest.rssi,
        deviceId: nearest.macAddress ?? 'mobile-device',
      );
    } finally {
      await subscription?.cancel();
    }
  }

  Future<void> _prepareScanning() async {
    try {
      await _requestAndroidRuntimePermissions();

      final authorized = await beacon.flutterBeacon.requestAuthorization;
      if (!authorized) {
        throw StateError('비콘 스캔 권한을 허용해주세요.');
      }

      final bluetoothState = await beacon.flutterBeacon.bluetoothState;
      if (bluetoothState != beacon.BluetoothState.stateOn) {
        await beacon.flutterBeacon.openBluetoothSettings;
        throw StateError('비콘 스캔을 위해 Bluetooth를 켜주세요.');
      }

      final locationEnabled =
          await beacon.flutterBeacon.checkLocationServicesIfEnabled;
      if (!locationEnabled) {
        await beacon.flutterBeacon.openLocationSettings;
        throw StateError('비콘 스캔을 위해 휴대폰 위치 서비스를 켜주세요.');
      }

      await beacon.flutterBeacon.setScanPeriod(1000);
      await beacon.flutterBeacon.setBetweenScanPeriod(500);
      await beacon.flutterBeacon.setUseTrackingCache(true);
      await beacon.flutterBeacon.setMaxTrackingAge(10000);

      final initialized = await beacon.flutterBeacon.initializeAndCheckScanning;
      if (!initialized) {
        throw StateError('비콘 스캔을 초기화하지 못했습니다.');
      }
    } on PlatformException catch (error) {
      throw StateError(error.message ?? '비콘 스캔 권한 또는 Bluetooth 상태를 확인해주세요.');
    }
  }

  Future<void> _requestAndroidRuntimePermissions() async {
    if (!Platform.isAndroid) {
      return;
    }

    final statuses = await <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final hasDeniedPermission = statuses.values.any(
      (status) => !status.isGranted,
    );

    if (!hasDeniedPermission) {
      return;
    }

    final hasPermanentlyDeniedPermission = statuses.values.any(
      (status) => status.isPermanentlyDenied,
    );

    if (hasPermanentlyDeniedPermission) {
      await openAppSettings();
      throw StateError('설정에서 위치와 Bluetooth 권한을 허용해주세요.');
    }

    throw StateError('비콘 스캔을 위해 위치와 Bluetooth 권한을 허용해주세요.');
  }

  List<beacon.Region> _scanRegions() {
    if (Platform.isIOS) {
      return [
        beacon.Region(
          identifier: 'beacon-attendance',
          proximityUUID: iBeaconUuid,
        ),
      ];
    }

    return [
      beacon.Region(identifier: 'beacon-attendance'),
    ];
  }
}
