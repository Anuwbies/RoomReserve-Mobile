import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'Login_Page.dart';
import 'NavigationBar_Page.dart';
import '../l10n/app_localizations.dart';

enum RegisterMethod { none, email, google }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  RegisterMethod _loadingMethod = RegisterMethod.none;
  bool get _isLoading => _loadingMethod != RegisterMethod.none;

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  String? _getNameValidationMessage({
    required AppLocalizations l10n,
    required String value,
    required String minLengthKey,
    required String maxLengthKey,
    required String invalidCharactersKey,
  }) {
    if (value.length < 3) {
      return l10n.get(minLengthKey);
    }

    if (value.length > 16) {
      return l10n.get(maxLengthKey);
    }

    final validNamePattern = RegExp(
      r'^[A-Za-z\u3040-\u30FF\u3400-\u4DBF\u4E00-\u9FFF\uAC00-\uD7AF]+$',
    );

    if (!validNamePattern.hasMatch(value)) {
      return l10n.get(invalidCharactersKey);
    }

    return null;
  }

  String? _getPasswordValidationMessage(
    AppLocalizations l10n,
    String password,
  ) {
    if (password.length < 8) {
      return l10n.get('passwordMinLength');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return l10n.get('passwordNeedsUppercase');
    }

    if (!password.contains(RegExp(r'\d'))) {
      return l10n.get('passwordNeedsNumber');
    }

    if (!password.contains(RegExp(r'[^A-Za-z0-9\s]'))) {
      return l10n.get('passwordNeedsSpecialCharacter');
    }

    if (password.contains(RegExp(r'\s'))) {
      return l10n.get('passwordNoSpaces');
    }

    return null;
  }

  // ---------------- FIRESTORE SAVE LOGIC ----------------
  Future<void> _saveUserToFirestore(User user, String fullName) async {
    try {
      // Use root-level 'users' collection as requested
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final docSnapshot = await userDoc.get();

      // Only set data if user doesn't exist to prevent overwriting roles
      if (!docSnapshot.exists) {
        await userDoc.set({
          'name': fullName,
          'email': user.email,
          'organizationName': '', // Default organization is blank
          'isEmailVerified': user.emailVerified,
          'languageCode': 'en',
          'photoURL': null,
          'platform': 'mobile',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // ---------------- EMAIL / PASSWORD REGISTER ----------------
  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if ([firstName, lastName, email, password, confirmPassword]
        .any((value) => value.isEmpty)) {
      _showError(l10n.get('allFieldsRequired'));
      return;
    }

    final firstNameValidationMessage = _getNameValidationMessage(
      l10n: l10n,
      value: firstName,
      minLengthKey: 'firstNameMinLength',
      maxLengthKey: 'firstNameMaxLength',
      invalidCharactersKey: 'firstNameInvalidCharacters',
    );

    if (firstNameValidationMessage != null) {
      _showError(firstNameValidationMessage);
      return;
    }

    final lastNameValidationMessage = _getNameValidationMessage(
      l10n: l10n,
      value: lastName,
      minLengthKey: 'lastNameMinLength',
      maxLengthKey: 'lastNameMaxLength',
      invalidCharactersKey: 'lastNameInvalidCharacters',
    );

    if (lastNameValidationMessage != null) {
      _showError(lastNameValidationMessage);
      return;
    }

    if (!_isValidEmail(email)) {
      _showError(l10n.get('invalidEmailFormat'));
      return;
    }

    final passwordValidationMessage =
        _getPasswordValidationMessage(l10n, password);

    if (passwordValidationMessage != null) {
      _showError(passwordValidationMessage);
      return;
    }

    if (password != confirmPassword) {
      _showError(l10n.get('passwordsDoNotMatch'));
      return;
    }

    setState(() => _loadingMethod = RegisterMethod.email);

    try {
      final UserCredential credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        final fullName = '$firstName $lastName';
        await user.updateDisplayName(fullName);
        await user.reload();

        // Save to Firestore BEFORE signing out
        await _saveUserToFirestore(user, fullName);

        // Do not keep user logged in for email registration flow
        await FirebaseAuth.instance.signOut();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? l10n.get('registrationFailed'));
      if (mounted) setState(() => _loadingMethod = RegisterMethod.none);
    } catch (_) {
      _showError(l10n.get('somethingWentWrong'));
      if (mounted) setState(() => _loadingMethod = RegisterMethod.none);
    }
  }

  // ---------------- GOOGLE REGISTER ----------------
  Future<void> _signUpWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loadingMethod = RegisterMethod.google);

    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _loadingMethod = RegisterMethod.none);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Save to Firestore
        await _saveUserToFirestore(
          user,
          user.displayName ?? 'Google User',
        );
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const NavigationBarPage(),
        ),
            (route) => false,
      );
    } catch (_) {
      _showError(l10n.get('googleSignInFailed'));
      if (mounted) setState(() => _loadingMethod = RegisterMethod.none);
    }
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isLoading,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        l10n.get('helloRegister'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _firstNameController,
                        decoration: _inputDecoration(l10n.get('firstName')),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        decoration: _inputDecoration(l10n.get('lastName')),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: _inputDecoration(l10n.get('email')),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        decoration: _inputDecoration(
                          l10n.get('password'),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                _obscurePassword
                                    ? 'lib/assets/images/eye closed.png'
                                    : 'lib/assets/images/eye open.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        decoration: _inputDecoration(
                          l10n.get('confirmPassword'),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                _obscureConfirmPassword
                                    ? 'lib/assets/images/eye closed.png'
                                    : 'lib/assets/images/eye open.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2937),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _loadingMethod == RegisterMethod.email
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            l10n.get('register'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l10n.get('orRegisterWith'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _signUpWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _loadingMethod == RegisterMethod.google
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'lib/assets/images/google icon.png',
                                height: 22,
                                width: 22,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata,
                                    size: 30),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.get('google'),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      text: l10n.get('alreadyHaveAccount'),
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: l10n.get('loginNow'),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
