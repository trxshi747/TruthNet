import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/widgets/dynamic_background.dart';

import 'package:model2/core/theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DynamicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Hero(
                    tag: 'logo',
                    child: Text(
                      'TruthNet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.righteous(
                        fontSize: 48,
                        color: AppTheme.peach, // Neon Cyan
                        shadows: [
                          Shadow(
                            blurRadius: 20.0,
                            color: AppTheme.peach.withOpacity(0.8),
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'CREATE_NEW_MEMBER_IDENTITY',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      color: AppTheme.coral, // Neon Magenta
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(blurRadius: 10, color: AppTheme.coral.withOpacity(0.8))
                      ]
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.5),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _firstNameController,
                    hint: 'FIRST_NAME',
                    icon: Icons.person_outline_rounded,
                    validator: (value) => value != null && value.isNotEmpty ? null : 'REQUIRED',
                  ).animate().fade(delay: 400.ms).slideX(begin: -0.2),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _lastNameController,
                    hint: 'LAST_NAME',
                    icon: Icons.person_outline_rounded,
                    validator: (value) => value != null && value.isNotEmpty ? null : 'REQUIRED',
                  ).animate().fade(delay: 500.ms).slideX(begin: 0.2),
                   const SizedBox(height: 15),
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'USERNAME',
                    icon: Icons.alternate_email_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'REQUIRED';
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                        return 'ALPHANUMERIC_ONLY';
                      }
                      return null;
                    },
                  ).animate().fade(delay: 600.ms).slideX(begin: -0.2),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'EMAIL_ADDRESS',
                    icon: Icons.email_outlined,
                    validator: (value) =>
                        value != null && value.contains('@') ? null : 'INVALID_EMAIL',
                  ).animate().fade(delay: 700.ms).slideX(begin: 0.2),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'ACCESS_KEY',
                    icon: Icons.lock_open_rounded,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'REQUIRED';
                      if (value.length < 8) return 'MIN_8_CHARS';
                      if (!value.contains(RegExp(r'[a-zA-Z]')) || !value.contains(RegExp(r'[0-9]'))) {
                        return 'MUST_CONTAIN_LETTERS_AND_NUMBERS';
                      }
                      return null;
                    },
                  ).animate().fade(delay: 800.ms).slideX(begin: -0.2),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'CONFIRM_ACCESS_KEY',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'REQUIRED';
                      if (value != _passwordController.text) return 'KEYS_DO_NOT_MATCH';
                      return null;
                    },
                  ).animate().fade(delay: 850.ms).slideX(begin: 0.2),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.peach.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.peach,
                        foregroundColor: AppTheme.darkPurple,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final response = await Provider.of<AuthProvider>(context, listen: false)
                              .register(
                                  _emailController.text,
                                  _passwordController.text,
                                  _firstNameController.text,
                                  _lastNameController.text,
                                  _usernameController.text,
                                  'Member'
                              );
                          if (response['success'] == true) {
                            Navigator.pushReplacementNamed(context, '/home');
                          } else {
                            String message;
                            switch (response['message']) {
                              case 'EMAIL_EXISTS':
                                message = 'EMAIL_ALREADY_IN_USE.SYS';
                                break;
                              case 'USERNAME_TAKEN':
                                message = 'USERNAME_ALREADY_IN_USE.SYS';
                                break;
                              case 'PASSWORD_TOO_WEAK_OR_TOO_SHORT':
                                message = 'ACCESS_KEY_PROTOCOL_VIOLATION';
                                break;
                              default:
                                message = 'REGISTRATION_FAILED: ${response['message'] ?? 'UNKNOWN_ERROR'}';
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  message, 
                                  style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)
                                ),
                                backgroundColor: AppTheme.coral,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'AUTHORIZE_IDENTITY',
                        style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                  ).animate().fade(delay: 900.ms).scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'ALREADY_HAVE_IDENTITY? LOGIN',
                      style: GoogleFonts.spaceMono(
                        color: AppTheme.coral,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 5, color: AppTheme.coral.withOpacity(0.5))]
                      ),
                    ),
                  ).animate().fade(delay: 1000.ms),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.peach.withOpacity(0.2)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.spaceMono(color: Colors.white.withOpacity(0.3), fontSize: 12),
              prefixIcon: Icon(icon, color: AppTheme.peach, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }
}
