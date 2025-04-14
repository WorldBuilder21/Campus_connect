import 'dart:io';

import 'package:campus_conn/auth/schemas/account.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:path/path.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef _) => AuthRepository();

class AuthRepository {
  final _client = Supabase.instance.client;

  Stream<AuthState> get authState => _client.auth.onAuthStateChange;

  String get userId => _client.auth.currentUser!.id;

  String get storageUrl => _client.storage.from('profiles').url;

  Stream<Account> getAccountByIdStream(String id) {
    return _client
        .from('account')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => Account.fromJson(data.first));
  }

  // get single user data
  Future<Account> getAccount(String id) async {
    try {
      final data = await _client.from('account').select().eq('id', id).single();

      if (data.isEmpty) {
        throw Exception('Account not found');
      }

      return Account.fromJson(data);
    } catch (e) {
      debugPrint('Error in getAccount: $e');
      if (e.toString().contains('PGRST116')) {
        // No rows returned
        throw Exception('Account not found in database');
      }
      rethrow;
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      String errorMessage = '';

      switch (e.code) {
        case 'invalid_credentials':
          errorMessage = 'Invalid email or password';
          break;

        // case 'email_not_confirmed':
        //   await resendVerificationEmail(email);
        //   errorMessage =
        //       'A verification link has been sent to your email, please verify your email before logging in.';
        //   break;

        case 'user_not_found':
          errorMessage = 'No account found with this email';
          break;

        case 'too_many_requests':
          errorMessage = 'Too many login attempts. Please try again later';
          break;

        case 'user_banned':
          errorMessage =
              'This account has been suspended. Please contact support';
          break;

        case 'email_provider_disabled':
          errorMessage = 'Email login is currently disabled';
          break;

        case 'request_timeout':
          errorMessage =
              'Request timed out. Please check your internet connection';
          break;

        case 'over_request_rate_limit':
          errorMessage =
              'Too many requests. Please wait a few minutes and try again';
          break;

        case 'session_expired':
          errorMessage = 'Your session has expired. Please login again';
          break;

        case 'weak_password':
          errorMessage = 'Password is too weak. Please use a stronger password';
          break;

        case 'email_exists':
          errorMessage = 'An account with this email already exists';
          break;

        case 'validation_failed':
          errorMessage = 'Please check your email and password format';
          break;

        default:
          errorMessage = 'An unexpected error occurred. Please try again later';
          debugPrint('Unhandled auth error code: ${e.code}');
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> uploadImage({
    required File file,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final imageExtension =
        file.path.split('/').last.split('.').last.toLowerCase();
    final imageId = '${basename(file.path)}_${DateTime.now()}';
    final imagePath = '$userId/$imageId';
    await _client.storage.from('profiles').uploadBinary(
          imagePath,
          file.readAsBytesSync(),
          fileOptions: FileOptions(
              // cacheControl: '3600',
              upsert: true,
              contentType: 'image/$imageExtension'),
        );
    final imageUrl = _client.storage.from('profiles').getPublicUrl(imagePath);
    // update the imag_url of the account in the database
    await _client.from('account').update({
      'image_id': imageId,
      'image_url': imageUrl,
    }).eq('id', userId);

    return;
  }

  Future<bool> checkUsernameExists({required String username}) async {
    final response = await _client
        .from('account')
        .select('username')
        .eq('username', username);
    return response.isNotEmpty;
  }

  Future<bool> checkEmailExists({required email}) async {
    final response =
        await _client.from('account').select('email').eq('email', email);
    return response.isNotEmpty;
  }

  Future<void> logout() => _client.auth.signOut();

  Future<void> addUserToDatabase({
    required String phoneNumber,
    required String type,
    required String email,
  }) async {
    try {
      final user = _client.auth.currentUser;

      if (user != null) {
        await _client.from('account').upsert({
          'id': user.id,
          'phone_number': phoneNumber,
          'type': type,
          'email': email,
        });
      }
    } catch (e) {
      debugPrint('Error adding user to database: $e');
    }
  }
}
