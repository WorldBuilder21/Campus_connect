import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:campus_conn/auth/providers/account_provider.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/auth/view/login/login_field.dart';
import 'package:campus_conn/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  debugPrint('Initializing authStateProvider');
  return ref.watch(authRepositoryProvider).authState;
});

final accountProvider = FutureProvider<Account?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);

  if (authState.session != null) {
    debugPrint(
        'AccountProvider: User is logged in with ID: ${authState.session!.user!.id}');
    try {
      final account = await ref
          .read(authRepositoryProvider)
          .getAccount(authState.session!.user.id);

      debugPrint(
          'AccountProvider: Account loaded successfully with ID: ${account.id}');

      // Update the currentAccount state
      ref.read(currentAccount.notifier).state = account;

      return account;
    } catch (e) {
      debugPrint('AccountProvider: Error loading account: $e');
      rethrow;
    }
  } else {
    debugPrint('AccountProvider: No active session, returning null account');
    return null;
  }
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  await dotenv.load(fileName: '.env');
  debugPrint('Environment variables loaded');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    const ProviderScope(
      child: Home(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MaterialApp(
      title: 'Campus connect',
      home: LoginField(),
    );
  }
}
