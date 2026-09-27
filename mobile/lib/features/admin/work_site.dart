class WorkSite {
  const WorkSite({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.active,
  });

  final int id;
  final String name;
  final String address;
  final String? description;
  final bool active;

  factory WorkSite.fromJson(Map<String, dynamic> json) {
    return WorkSite(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      description: json['description'] as String?,
      active: json['active'] as bool,
    );
  }
}
