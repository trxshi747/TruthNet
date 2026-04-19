import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/providers/auth_provider.dart';
import 'package:model2/widgets/dynamic_background.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
                  const SizedBox(height: 60),
                  Hero(
                    tag: 'logo',
                    child: Text(
                      'TruthNet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.righteous(
                        fontSize: 48,
                        color: const Color(0xFFF0C38E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'CREATE_NEW_MEMBER_IDENTITY',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      color: const Color(0xFFF1AA9B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'FULL_NAME',
                    icon: Icons.person_outline_rounded,
                    validator: (value) => value != null && value.isNotEmpty ? null : 'REQUIRED',
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'EMAIL_ADDRESS',
                    icon: Icons.alternate_email_rounded,
                    validator: (value) =>
                        value != null && value.contains('@') ? null : 'INVALID_EMAIL',
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'ACCESS_KEY',
                    icon: Icons.lock_open_rounded,
                    isPassword: true,
                    validator: (value) =>
                        value != null && value.length >= 6 ? null : 'MIN_6_CHARS',
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0C38E),
                      foregroundColor: const Color(0xFF312C51),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 10,
                      shadowColor: const Color(0xFFF0C38E).withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await Provider.of<AuthProvider>(context, listen: false)
                            .register(
                                _emailController.text, 
                                _passwordController.text,
                                _nameController.text, 
                                'Member' // Role is fixed to Member for public signups
                            );
                        if (success) {
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('REGISTRATION_FAILED: SYSTEM_ERROR')),
                          );
                        }
                      }
                    },
                    child: Text(
                      'AUTHORIZE_IDENTITY',
                      style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'ALREADY_HAVE_IDENTITY? LOGIN',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFFF1AA9B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        ),
        validator: validator,
      ),
    );
  }
}
