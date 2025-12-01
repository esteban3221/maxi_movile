class IpAddress {
  final int? id;
  final String alias;
  final String address;
  final DateTime dateAdded;
  final String? description;

  IpAddress({
    this.id,
    required this.alias,
    required this.address,
    required this.dateAdded,
    this.description,
  });

  // ✅ Desde base de datos
  factory IpAddress.fromJson(Map<String, dynamic> json) {
    return IpAddress(
      id: json['id'],
      alias: json['alias'] ?? '',
      address: json['address'],
      dateAdded: DateTime.parse(json['date_added']),
      description: json['description'],
    );
  }

  // ✅ Para base de datos
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alias': alias,
      'address': address,
      'description': description,
      'date_added': dateAdded.toIso8601String(),
    };
  }
}
