import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/widgets/dynamic_background.dart';

import 'package:model2/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  const SizedBox(height: 100),
                  Hero(
                    tag: 'logo',
                    child: Text(
                      'TruthNet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.righteous(
                        fontSize: 64,
                        color: AppTheme.peach, // Neon Cyan
                        letterSpacing: -2,
                        shadows: [
                          Shadow(
                            blurRadius: 25.0,
                            color: AppTheme.peach.withOpacity(0.8),
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'AUTHENTIC_CONNECTIONS.SYS',
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
                  const SizedBox(height: 80),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'USER_ID_OR_EMAIL',
                    icon: Icons.alternate_email_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'REQUIRED';
                      return null;
                    },
                  ).animate().fade(delay: 500.ms).slideX(begin: -0.2),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'ACCESS_KEY',
                    icon: Icons.lock_open_rounded,
                    isPassword: true,
                    validator: (value) =>
                        value != null && value.length >= 6 ? null : 'KEY_TOO_SHORT',
                  ).animate().fade(delay: 600.ms).slideX(begin: 0.2),
                  const SizedBox(height: 40),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final response = await Provider.of<AuthProvider>(context, listen: false).login(
                            _emailController.text,
                            _passwordController.text,
                          );

                          if (response['success'] == true) {
                            final role = Provider.of<AuthProvider>(context, listen: false).role;
                            if (role == UserRole.admin) {
                              Navigator.pushReplacementNamed(context, '/admin');
                            } else if (role == UserRole.moderator) {
                              Navigator.pushReplacementNamed(context, '/mod');
                            } else {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          } else {
                            String message;
                            switch (response['message']) {
                              case 'INVALID_CREDENTIALS':
                                message = 'ACCESS_DENIED: INVALID_CREDENTIALS';
                                break;
                              case 'USER_NOT_FOUND':
                                message = 'IDENTITY_NOT_FOUND.SYS';
                                break;
                              case 'ACCOUNT_DEACTIVATED':
                                message = 'ACCOUNT_DEACTIVATED: Please contact support.';
                                break;
                              case 'ACCOUNT_BANNED':
                                message = 'ACCOUNT_PERMANENTLY_BANNED';
                                break;
                              case 'ACCOUNT_SUSPENDED':
                                message = response['detail'] ?? 'ACCOUNT_SUSPENDED';
                                break;
                              default:
                                message = 'LOGIN_FAILED: ${response['message'] ?? 'UNKNOWN_ERROR'}';
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  message, 
                                  style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)
                                ),
                                backgroundColor: AppTheme.coral,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'INITIALIZE_SESSION',
                        style: GoogleFonts.spaceMono(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false).loginAsGuest();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Text(
                      'BYPASS_AUTH (GUEST_MODE)',
                      style: GoogleFonts.spaceMono(
                        color: AppTheme.peach, // Neon Yellow
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        shadows: [Shadow(blurRadius: 5, color: AppTheme.peach.withOpacity(0.5))]
                      ),
                    ),
                  ).animate().fade(delay: 900.ms),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "NO_ACCOUNT? ",
                        style: GoogleFonts.spaceMono(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Flexible(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: Text(
                            "CREATE_IDENTITY",
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.peach,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.peach,
                            ),
                          ),
                        ),
                      ),
                    ],
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
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
            validator: (val) {
              final result = validator?.call(val);
              return result;
            },
          ),
        ),
      ),
    );
  }
}
