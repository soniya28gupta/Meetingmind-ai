enum WearableDeviceType {
  xiaomiBand,
  xiaomiWatch,
  fitbit,
  ouraRing,
  samsungWatch,
  pixelWatch,
  polarHeartRate,
  garminHeartRate,
  genericHeartRate,
  genericHealth,
  other,
}

class WearableDevice {
  final String id;
  final String name;
  final WearableDeviceType type;
  final int rssi;
  final int? batteryLevel;
  final bool isConnected;
  final String manufacturer;
  final String modelNumber;
  final String firmwareVersion;
  final List<String> supportedSensors;
  final List<String> supportedServices;
  final Map<String, dynamic> advertisementData;
  final Map<int, List<int>> manufacturerData;

  WearableDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.rssi,
    this.batteryLevel,
    this.isConnected = false,
    this.manufacturer = 'Unknown',
    this.modelNumber = 'Unknown',
    this.firmwareVersion = 'v1.0.0',
    this.supportedSensors = const [],
    this.supportedServices = const [],
    this.advertisementData = const {},
    this.manufacturerData = const {},
  });

  WearableDevice copyWith({
    String? id,
    String? name,
    WearableDeviceType? type,
    int? rssi,
    int? batteryLevel,
    bool? isConnected,
    String? manufacturer,
    String? modelNumber,
    String? firmwareVersion,
    List<String>? supportedSensors,
    List<String>? supportedServices,
    Map<String, dynamic>? advertisementData,
    Map<int, List<int>>? manufacturerData,
  }) {
    return WearableDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rssi: rssi ?? this.rssi,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isConnected: isConnected ?? this.isConnected,
      manufacturer: manufacturer ?? this.manufacturer,
      modelNumber: modelNumber ?? this.modelNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      supportedSensors: supportedSensors ?? this.supportedSensors,
      supportedServices: supportedServices ?? this.supportedServices,
      advertisementData: advertisementData ?? this.advertisementData,
      manufacturerData: manufacturerData ?? this.manufacturerData,
    );
  }
}
