import 'package:campus_conn/auth/api/auth_repository.dart';
import 'package:campus_conn/auth/providers/account_provider.dart';
import 'package:campus_conn/auth/schemas/account.dart';
import 'package:campus_conn/auth/view/login/forgot_password_screen.dart';
import 'package:campus_conn/auth/view/login/login_field.dart';
import 'package:campus_conn/auth/view/signup/signup_walkthrough.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/home/home.dart';
import 'package:campus_conn/layout.dart';
import 'package:campus_conn/location/services/location_services.dart';
import 'package:campus_conn/notifications/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import Firebase options file (you'll need to generate this)
import 'firebase_options.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Auth state provider - using autoDispose to prevent memory leaks
final authStateProvider = StreamProvider.autoDispose<AuthState>((ref) {
  debugPrint('Initializing authStateProvider');
  return ref.watch(authRepositoryProvider).authState;
});

// Account provider with auto-dispose
final accountProvider = FutureProvider.autoDispose<Account?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);

  if (authState.session != null) {
    debugPrint(
        'AccountProvider: User is logged in with ID: ${authState.session!.user.id}');
    try {
      final account = await ref
          .read(authRepositoryProvider)
          .getAccount(authState.session!.user.id);

      debugPrint(
          'AccountProvider: Account loaded successfully with ID: ${account.id}');

      // Update the currentAccount state
      ref.read(currentAccount.notifier).state = account;

      // Initialize the background location service when user logs in
      // Make sure to call this after the user is authenticated
      await LocationService().initializeService();

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

// User data provider - simplified and with auto-dispose
final userDataProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  debugPrint('UserDataProvider: Starting to load user data');
  final account = await ref.watch(accountProvider.future);

  if (account == null) {
    debugPrint('UserDataProvider: No account available');
    return null;
  }

  debugPrint('UserDataProvider: Account loaded with ID: ${account.id}');
  return account;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('App starting...');

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: '.env');
  debugPrint('Environment variables loaded');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Firebase initialized');

  // Request notification permissions for Android
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('Firebase Messaging permissions requested');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
  debugPrint('Supabase initialized');

  // Clear keyboard state
  ServicesBinding.instance.keyboard.clearState();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Run the app with custom error handling
  runApp(
    ProviderScope(
      // Using ProviderScope with observers for better debugging
      observers: [ProviderLogger()],
      child: const MyApp(),
    ),
  );
  debugPrint('App started');
}

// Custom provider logger for debugging
class ProviderLogger extends ProviderObserver {
  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    debugPrint('Provider disposed: ${provider.name ?? provider.runtimeType}');
    super.didDisposeProvider(provider, container);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('Provider updated: ${provider.name ?? provider.runtimeType}');
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Building MyApp');

    // Watch auth state
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CampusConn',
      theme: AppTheme.lightTheme,
      home: authState.when(
        loading: () => const SplashScreen(),
        error: (_, __) => const LoginField(),
        data: (state) {
          if (state.session != null) {
            return ref.watch(userDataProvider).when(
                  loading: () => const SplashScreen(),
                  error: (_, __) => const LoginField(),
                  data: (userData) {
                    if (userData == null) {
                      return const LoginField();
                    } else {
                      return const Layout();
                    }
                  },
                );
          }
          return const LoginField();
        },
      ),
      routes: {
        LoginField.routeName: (context) => const LoginField(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        SignupWalkthrough.routeName: (context) => const SignupWalkthrough(),
        NotificationScreen.routeName: (context) => const NotificationScreen(),
        ForgotPasswordScreen.routeName: (context) =>
            const ForgotPasswordScreen(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'CampusConn',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
