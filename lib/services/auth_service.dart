import '../database/database_helper.dart';
import '../utils/validation_utils.dart';

class AuthService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String userType,
  }) async {
    try {
      // Validate inputs
      final nameError = ValidationUtils.validateFullName(fullName);
      if (nameError != null) {
        return {'success': false, 'message': nameError};
      }

      if (!ValidationUtils.isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      final passwordError = ValidationUtils.validatePassword(password);
      if (passwordError != null) {
        return {'success': false, 'message': passwordError};
      }

      final confirmPasswordError = ValidationUtils.validateConfirmPassword(
        password,
        confirmPassword,
      );
      if (confirmPasswordError != null) {
        return {'success': false, 'message': confirmPasswordError};
      }

      if (!ValidationUtils.isValidUserType(userType)) {
        return {'success': false, 'message': 'Please select a valid user type'};
      }

      // Check if email already exists
      final emailExists = await _databaseHelper.emailExists(email);
      if (emailExists) {
        return {
          'success': false,
          'message':
              'Email already registered. Please use a different email or login.',
        };
      }

      // Register user
      final userId = await _databaseHelper.registerUser(
        fullName: fullName,
        email: email,
        password: password,
        userType: userType,
      );

      if (userId > 0) {
        return {
          'success': true,
          'message': 'Registration successful! Please login.',
          'userId': userId,
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Please enter both email and password',
        };
      }

      if (!ValidationUtils.isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      // Attempt login
      final user = await _databaseHelper.loginUser(
        email: email,
        password: password,
      );

      if (user != null) {
        return {'success': true, 'message': 'Login successful!', 'user': user};
      } else {
        return {'success': false, 'message': 'Invalid email or password'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    try {
      return await _databaseHelper.getUserById(id);
    } catch (e) {
      return null;
    }
  }
}
