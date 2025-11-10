class AppUser {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? carPlate;
  final String? carModel;
  final String? carMake;
  final String? photoUrl;
  final String? deviceToken;
  final bool onboardingComplete;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.carPlate,
    this.carModel,
    this.carMake,
    this.photoUrl,
    this.deviceToken,
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'carPlate': carPlate,
    'carModel': carModel,
    'carMake': carMake,
        'photoUrl': photoUrl,
        'deviceToken': deviceToken,
    'onboardingComplete': onboardingComplete,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};
    return AppUser(
      id: id,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      carPlate: map['carPlate'] as String?,
      carModel: map['carModel'] as String?,
      carMake: map['carMake'] as String?,
      photoUrl: map['photoUrl'] as String?,
      deviceToken: map['deviceToken'] as String?,
      onboardingComplete: map['onboardingComplete'] is bool
          ? map['onboardingComplete'] as bool
          : false,
    );
  }
}
