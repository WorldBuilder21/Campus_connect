import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.g.dart';
part 'account.freezed.dart';

@freezed
class Account with _$Account {
  const factory Account({
    required String? id,
    required String? image_url,
    required String? image_id,
    required String? email,
    required String? username,
    required bool? email_verified,
    required String? fcm_token,
    required DateTime? created_at,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
