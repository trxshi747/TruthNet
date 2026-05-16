import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:model2/features/auth/application/auth_provider.dart';
import 'package:model2/core/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final response = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      if (response['success'] == true) {
        final notifier = ref.read(authProvider.notifier);
        if (notifier.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (notifier.isModerator) {
          Navigator.pushReplacementNamed(context, '/mod');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        final message = response['message'] ?? 'Login failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'TruthNet.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      letterSpacing: -2.0,
                    ),
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 12),
                  Text(
                    'The transparent social network.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 60),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email address',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value != null && value.contains('@') ? null : 'Valid email required',
                  ).animate().fade(delay: 300.ms).slideX(begin: -0.1),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (value) => value != null && value.length >= 6 ? null : 'Min 6 characters',
                  ).animate().fade(delay: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Sign In',
                    isLoading: authState.isLoading,
                    onPressed: _handleLogin,
                  ).animate().fade(delay: 500.ms).scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).loginAsGuest();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48), // Fitts' Law
                    ),
                    child: Text(
                      'Continue as Guest',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ).animate().fade(delay: 600.ms),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 48), // Fitts' Law
                        ),
                        child: Text(
                          "Sign Up",
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 700.ms),
                  const SizedBox(height: 40),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: validator,
    );
  }
}
