class AppUser {
  final String id;
  final String? name;
  final String? email;
  final String? carPlate;
  final String? carModel;
  final String? carMake;
  final String? carColor;
  final String? photoUrl;
  final String? deviceToken;
  final double? lastLat;
  final double? lastLng;
  final bool onboardingComplete;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.carPlate,
    this.carModel,
    this.carMake,
    this.carColor,
    this.photoUrl,
    this.deviceToken,
    this.lastLat,
    this.lastLng,
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'carPlate': carPlate,
    'carModel': carModel,
    'carMake': carMake,
    'carColor': carColor,
        'photoUrl': photoUrl,
        'deviceToken': deviceToken,
        'lastLat': lastLat,
        'lastLng': lastLng,
    'onboardingComplete': onboardingComplete,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};
    return AppUser(
      id: id,
      name: map['name'] as String?,
      email: map['email'] as String?,
      carPlate: map['carPlate'] as String?,
      carModel: map['carModel'] as String?,
      carMake: map['carMake'] as String?,
      carColor: map['carColor'] as String?,
      photoUrl: map['photoUrl'] as String?,
      deviceToken: map['deviceToken'] as String?,
      lastLat:
          (map['lastLat'] is num) ? (map['lastLat'] as num).toDouble() : null,
      lastLng:
          (map['lastLng'] is num) ? (map['lastLng'] as num).toDouble() : null,
      onboardingComplete: map['onboardingComplete'] is bool
          ? map['onboardingComplete'] as bool
          : false,
    );
  }
}
