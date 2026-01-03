import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_reminder/utils/auth_error_helper.dart';

void main() {
  group('AuthErrorHelper', () {
    test('Returns default error for null', () {
      expect(AuthErrorHelper.getErrorMessage(null),
          'An unexpected error occurred. Please try again.');
    });

    group('String-based errors', () {
      test('Handles invalid credentials', () {
        expect(
            AuthErrorHelper.getErrorMessage('Exception: invalid_credentials'),
            'Invalid email or password. Please check your credentials and try again.');
      });

      test('Handles email not confirmed', () {
        expect(
            AuthErrorHelper.getErrorMessage('email not confirmed'),
            'Please verify your email address before signing in. Check your inbox for a verification link.');
      });

      test('Handles user not found', () {
        expect(
            AuthErrorHelper.getErrorMessage('user not found'),
            'No account found with this email address. Please sign up first.');
      });

      test('Handles already registered', () {
        expect(
            AuthErrorHelper.getErrorMessage('email already registered'),
            'An account with this email already exists. Please sign in instead.');
      });

      test('Handles network error', () {
        expect(
            AuthErrorHelper.getErrorMessage('Network error occurred'),
            'Network error. Please check your internet connection and try again.');
      });

      test('Handles timeout', () {
        expect(
            AuthErrorHelper.getErrorMessage('Connection timeout'),
            'Request timed out. Please try again.');
      });

      test('Handles too many requests', () {
        expect(
            AuthErrorHelper.getErrorMessage('Too many requests'),
            'Too many attempts. Please wait a moment and try again.');
      });
    });

    group('AuthException', () {
      test('Handles 400 with invalid credentials message', () {
        final error = AuthException('Invalid login credentials', statusCode: '400');
        expect(AuthErrorHelper.getErrorMessage(error),
            'Invalid email or password. Please check your credentials and try again.');
      });

      test('Handles 400 with other message', () {
        final error = AuthException('Bad Request', statusCode: '400');
        expect(AuthErrorHelper.getErrorMessage(error),
            'Invalid request. Please check your information and try again.');
      });

      test('Handles 401', () {
        final error = AuthException('Unauthorized', statusCode: '401');
        expect(AuthErrorHelper.getErrorMessage(error),
            'Invalid email or password. Please check your credentials and try again.');
      });

      test('Handles 403', () {
        final error = AuthException('Forbidden', statusCode: '403');
        expect(AuthErrorHelper.getErrorMessage(error),
            'Access denied. Please verify your email address.');
      });

      test('Handles 404', () {
        final error = AuthException('Not Found', statusCode: '404');
        expect(AuthErrorHelper.getErrorMessage(error),
            'Account not found. Please sign up first.');
      });

      test('Handles 422', () {
        final error = AuthException('Unprocessable Entity', statusCode: '422');
        expect(AuthErrorHelper.getErrorMessage(error),
            'Invalid email format. Please enter a valid email address.');
      });

      test('Handles 429', () {
        final error = AuthException('Too Many Requests', statusCode: '429');
        expect(AuthErrorHelper.getErrorMessage(error),
            'Too many attempts. Please wait a moment and try again.');
      });

      test('Handles 500', () {
        final error = AuthException('Internal Server Error', statusCode: '500');
        expect(AuthErrorHelper.getErrorMessage(error),
            'Server error. Please try again later.');
      });

      test('Handles default case cleans message', () {
         final error = AuthException('some error code: 123', statusCode: '418');
         // Clean logic: removes 'code: \w+'
         expect(AuthErrorHelper.getErrorMessage(error), 'Some error 123');
      });
    });

    group('Generic Exception Cleaning', () {
      test('Cleans "Exception: authapiexception ..."', () {
         expect(
             AuthErrorHelper.getErrorMessage('Exception: authapiexception(message: Some error)'),
             'Some error');
      });

      test('Maps "authapiexception" in exception string to invalid credentials', () {
         expect(
             AuthErrorHelper.getErrorMessage('Exception: authapiexception'),
             'Invalid email or password. Please check your credentials and try again.');
      });
    });
  });
}
