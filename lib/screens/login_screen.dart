import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/widgets/dynamic_background.dart';

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
                        color: const Color(0xFFF0C38E),
                        letterSpacing: -2,
                        shadows: [
                          Shadow(
                            blurRadius: 20.0,
                            color: const Color(0xFF48426D).withOpacity(0.8),
                            offset: const Offset(0, 10),
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
                      color: const Color(0xFFF1AA9B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 80),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'USER_ID / EMAIL',
                    icon: Icons.alternate_email_rounded,
                    validator: (value) =>
                        value != null && value.contains('@') ? null : 'INVALID_EMAIL',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'ACCESS_KEY',
                    icon: Icons.lock_open_rounded,
                    isPassword: true,
                    validator: (value) =>
                        value != null && value.length >= 6 ? null : 'KEY_TOO_SHORT',
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0C38E),
                      foregroundColor: const Color(0xFF312C51),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 10,
                      shadowColor: const Color(0xFFF0C38E).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await Provider.of<AuthProvider>(context, listen: false).login(
                          _emailController.text,
                          _passwordController.text,
                        );
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final role = auth.role;

                        if (success) {
                          if (role == UserRole.admin) {
                            Navigator.pushReplacementNamed(context, '/admin');
                          }
                          else if (role == UserRole.moderator) {
                            Navigator.pushReplacementNamed(context, '/mod');
                          }
                          else if (role == UserRole.member) { // for the members
                            Navigator.pushReplacementNamed(context, '/home');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(
                                  'LOGIN_FAILED: UNKNOWN_IDENTITY')),
                            );
                          }
                        }
                        /*if (success) {
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('LOGIN_FAILED: UNKNOWN_IDENTITY')),
                          );
                        }*/
                      }
                    },
                    child: Text(
                      'INITIALIZE_SESSION',
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false).loginAsGuest();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Text(
                      'BYPASS_AUTH (GUEST_MODE)',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFFF1AA9B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
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
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: Text(
                          "CREATE_IDENTITY",
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFFF0C38E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF48426D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceMono(color: Colors.white.withOpacity(0.3), fontSize: 12),
          prefixIcon: Icon(icon, color: const Color(0xFFF0C38E), size: 20),
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
    );
  }
}
