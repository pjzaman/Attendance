/// A biometric / time-tracking device registered with the app. v1
/// surfaces the existing single ZKTeco UFACE-800 connection from
/// [AppConfig]; multi-device sync is a future expansion.
class Device {
  Device({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.ipAddress,
    required this.port,
    this.serialNumber,
    this.officeLocation,
    this.isActive = true,
    this.notes,
    this.lastConnectedAt,
    this.lastSyncAt,
    this.commKey = 0,
    this.connectTimeoutMs = 5000,
    this.recvTimeoutMs = 10000,
  });

  final String id;
  final String name;
  final String brand;
  final String model;
  final String ipAddress;
  final int port;
  final String? serialNumber;

  /// Vendor "comm key" handshake value. `0` = no auth required (the
  /// default for ZKTeco devices out of the box).
  final int commKey;
  final int connectTimeoutMs;
  final int recvTimeoutMs;

  /// Human-friendly tag (e.g. "Main Gate", "Factory B"). Once an
  /// `OfficeLocation` model exists, this becomes a foreign key.
  final String? officeLocation;
  final bool isActive;
  final String? notes;
  final DateTime? lastConnectedAt;
  final DateTime? lastSyncAt;

  String get connectionLabel => '$ipAddress:$port';

  Device copyWith({
    String? name,
    String? brand,
    String? model,
    String? ipAddress,
    int? port,
    String? serialNumber,
    String? officeLocation,
    bool? isActive,
    String? notes,
    DateTime? lastConnectedAt,
    DateTime? lastSyncAt,
    int? commKey,
    int? connectTimeoutMs,
    int? recvTimeoutMs,
  }) =>
      Device(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        ipAddress: ipAddress ?? this.ipAddress,
        port: port ?? this.port,
        serialNumber: serialNumber ?? this.serialNumber,
        officeLocation: officeLocation ?? this.officeLocation,
        isActive: isActive ?? this.isActive,
        notes: notes ?? this.notes,
        lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        commKey: commKey ?? this.commKey,
        connectTimeoutMs: connectTimeoutMs ?? this.connectTimeoutMs,
        recvTimeoutMs: recvTimeoutMs ?? this.recvTimeoutMs,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'brand': brand,
        'model': model,
        'ip_address': ipAddress,
        'port': port,
        'serial_number': serialNumber,
        'office_location': officeLocation,
        'is_active': isActive ? 1 : 0,
        'notes': notes,
        'last_connected_at':
            lastConnectedAt?.toUtc().toIso8601String(),
        'last_sync_at': lastSyncAt?.toUtc().toIso8601String(),
        'comm_key': commKey,
        'connect_timeout_ms': connectTimeoutMs,
        'recv_timeout_ms': recvTimeoutMs,
      };

  factory Device.fromMap(Map<String, Object?> m) => Device(
        id: m['id']! as String,
        name: m['name']! as String,
        brand: (m['brand'] as String?) ?? '',
        model: (m['model'] as String?) ?? '',
        ipAddress: m['ip_address']! as String,
        port: (m['port'] as int?) ?? 0,
        serialNumber: m['serial_number'] as String?,
        officeLocation: m['office_location'] as String?,
        isActive: ((m['is_active'] as int?) ?? 1) == 1,
        notes: m['notes'] as String?,
        lastConnectedAt: m['last_connected_at'] == null
            ? null
            : DateTime.parse(m['last_connected_at']! as String).toLocal(),
        lastSyncAt: m['last_sync_at'] == null
            ? null
            : DateTime.parse(m['last_sync_at']! as String).toLocal(),
        commKey: (m['comm_key'] as int?) ?? 0,
        connectTimeoutMs: (m['connect_timeout_ms'] as int?) ?? 5000,
        recvTimeoutMs: (m['recv_timeout_ms'] as int?) ?? 10000,
      );
}
