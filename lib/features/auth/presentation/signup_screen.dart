import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:model2/features/auth/application/auth_provider.dart';
import 'package:model2/core/widgets/primary_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final response = await ref.read(authProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
            _usernameController.text.trim(),
            'Member',
          );

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final message = response['message'] ?? 'Registration failed. Please try again.';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          // Ensure touch target constraint
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Create Account.',
                  style: theme.textTheme.displaySmall?.copyWith(
                    letterSpacing: -1.0,
                  ),
                ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Text(
                  'Join the transparent network.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        hint: 'First name',
                        validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
                      ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        hint: 'Last name',
                        validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
                      ).animate().fade(delay: 250.ms).slideX(begin: 0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  hint: 'Username',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.contains(' ')) return 'No spaces allowed';
                    return null;
                  },
                ).animate().fade(delay: 300.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@') ? null : 'Valid email required',
                ).animate().fade(delay: 350.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  isPassword: true,
                  validator: (value) => value != null && value.length >= 6 ? null : 'Min 6 characters',
                ).animate().fade(delay: 400.ms).slideX(begin: -0.1),
                const SizedBox(height: 40),
                PrimaryButton(
                  label: 'Sign Up',
                  isLoading: authState.isLoading,
                  onPressed: _handleSignUp,
                ).animate().fade(delay: 500.ms).scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
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
