import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_user.g.dart';

@riverpod
Stream<User?> authUser(AuthUserRef ref) async* {
  final authStream = ref.read(authRepositoryProvider).authState;

  await for (final authState in authStream) {
    yield authState.session?.user;
  }
}
