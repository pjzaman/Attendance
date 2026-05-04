/// A physical office / workspace where employees punch in. Per the doc
/// §4.10 HR Management: "Office Location: name, short name, contact
/// info." Referenced by [Device] and (future) [EmployeeProfile] for
/// per-location filtering and reporting.
class OfficeLocation {
  OfficeLocation({
    required this.id,
    required this.name,
    this.shortName,
    this.address,
    this.city,
    this.country,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? shortName;
  final String? address;
  final String? city;
  final String? country;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final bool isActive;

  OfficeLocation copyWith({
    String? name,
    String? shortName,
    String? address,
    String? city,
    String? country,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    bool? isActive,
  }) =>
      OfficeLocation(
        id: id,
        name: name ?? this.name,
        shortName: shortName ?? this.shortName,
        address: address ?? this.address,
        city: city ?? this.city,
        country: country ?? this.country,
        contactName: contactName ?? this.contactName,
        contactPhone: contactPhone ?? this.contactPhone,
        contactEmail: contactEmail ?? this.contactEmail,
        isActive: isActive ?? this.isActive,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'short_name': shortName,
        'address': address,
        'city': city,
        'country': country,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'is_active': isActive ? 1 : 0,
      };

  factory OfficeLocation.fromMap(Map<String, Object?> m) => OfficeLocation(
        id: m['id']! as String,
        name: m['name']! as String,
        shortName: m['short_name'] as String?,
        address: m['address'] as String?,
        city: m['city'] as String?,
        country: m['country'] as String?,
        contactName: m['contact_name'] as String?,
        contactPhone: m['contact_phone'] as String?,
        contactEmail: m['contact_email'] as String?,
        isActive: ((m['is_active'] as int?) ?? 1) == 1,
      );
}
