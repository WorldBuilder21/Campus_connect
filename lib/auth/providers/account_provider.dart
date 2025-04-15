import 'package:campus_conn/auth/schemas/account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

StateProvider<Account> currentAccount = StateProvider<Account>((ref) {
  return Account(
    id: '',
    image_url: '',
    image_id: '',
    email: '',
    username: '',
    email_verified: false,
    fcm_token: '',
    created_at: DateTime.now(),
  );
});
