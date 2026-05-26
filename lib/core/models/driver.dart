class Vehicle {
  final int id;
  final String plate;
  final String make;
  final String modelName;
  final String? type;

  Vehicle({required this.id, required this.plate, required this.make, required this.modelName, this.type});

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: (j['id'] as num).toInt(),
        plate: j['plate'] as String,
        make: j['make'] as String,
        modelName: j['model_name'] as String,
        type: j['type'] as String?,
      );
}

class Driver {
  final int id;
  final String name;
  final String status;
  final String phone;
  final String? phoneAlt;
  final String? email;
  final String? loginEmail;
  final String? cardId;
  final String? nationalId;
  final String? address;
  final String? birthRegion;
  final String? birthDistrict;
  final String? licenseNumber;
  final String? licenseClass;
  final List<String>? licenseClasses;
  final DateTime? licenseExpiry;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? photoUrl;
  final Vehicle? vehicle;

  Driver({
    required this.id,
    required this.name,
    required this.status,
    required this.phone,
    this.phoneAlt,
    this.email,
    this.loginEmail,
    this.cardId,
    this.nationalId,
    this.address,
    this.birthRegion,
    this.birthDistrict,
    this.licenseNumber,
    this.licenseClass,
    this.licenseClasses,
    this.licenseExpiry,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.photoUrl,
    this.vehicle,
  });

  factory Driver.fromJson(Map<String, dynamic> j) {
    // license_classes may arrive as JSON array or null
    List<String>? classes;
    final raw = j['license_classes'];
    if (raw is List) {
      classes = raw.map((e) => e.toString()).toList();
    }

    return Driver(
      id: (j['id'] as num).toInt(),
      name: j['name'] as String,
      status: j['status'] as String,
      phone: j['phone'] as String,
      phoneAlt: j['phone_alt'] as String?,
      email: j['email'] as String?,
      loginEmail: j['login_email'] as String?,
      cardId: j['card_id'] as String?,
      nationalId: j['national_id'] as String?,
      address: j['address'] as String?,
      birthRegion: j['birth_region'] as String?,
      birthDistrict: j['birth_district'] as String?,
      licenseNumber: j['license_number'] as String?,
      licenseClass: j['license_class'] as String?,
      licenseClasses: classes,
      licenseExpiry: j['license_expiry'] != null
          ? DateTime.parse(j['license_expiry'] as String)
          : null,
      emergencyContactName: j['emergency_contact_name'] as String?,
      emergencyContactPhone: j['emergency_contact_phone'] as String?,
      photoUrl: j['photo_url'] as String?,
      vehicle: j['vehicle'] != null
          ? Vehicle.fromJson(j['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }
}
