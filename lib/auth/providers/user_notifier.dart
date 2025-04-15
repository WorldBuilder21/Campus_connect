import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_notifier.g.dart';

@Riverpod(keepAlive: true)
Stream<Account> userNotifier(UserNotifierRef ref, String id) async* {
  final accountStream =
      ref.read(authRepositoryProvider).getAccountByIdStream(id);

  // return accountStream;

  await for (final acc in accountStream) {
    yield acc;
  }
}
