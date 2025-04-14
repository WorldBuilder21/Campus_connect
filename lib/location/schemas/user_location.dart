import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_location.g.dart';
part 'user_location.freezed.dart';

@freezed
class UserLocation with _$UserLocation {
  const factory UserLocation({
    required String id,
    required String userId,
    required double latitude,
    required double longitude,
    required DateTime lastUpdated,
    double? accuracy,
    String? locationName,
  }) = _UserLocation;

  factory UserLocation.fromJson(Map<String, dynamic> json) =>
      _$UserLocationFromJson(json);
}
