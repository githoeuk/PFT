class Beacon {
  const Beacon({
    required this.id,
    required this.workSiteId,
    required this.workSiteName,
    required this.uuid,
    required this.major,
    required this.minor,
    required this.name,
    required this.rssiThreshold,
    required this.active,
  });

  final int id;
  final int workSiteId;
  final String workSiteName;
  final String uuid;
  final int major;
  final int minor;
  final String name;
  final int rssiThreshold;
  final bool active;

  factory Beacon.fromJson(Map<String, dynamic> json) {
    return Beacon(
      id: json['id'] as int,
      workSiteId: json['workSiteId'] as int,
      workSiteName: json['workSiteName'] as String,
      uuid: json['uuid'] as String,
      major: json['major'] as int,
      minor: json['minor'] as int,
      name: json['name'] as String,
      rssiThreshold: json['rssiThreshold'] as int,
      active: json['active'] as bool,
    );
  }
}
