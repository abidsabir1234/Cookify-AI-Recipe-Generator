import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final prefs = await SharedPreferences.getInstance();
      final String username = _usernameController.text.trim().toLowerCase();
      final String password = _passwordController.text.trim();

      // Load existing users map
      final String? usersJson = prefs.getString('cookify_users');
      final Map<String, dynamic> users =
          usersJson != null ? json.decode(usersJson) as Map<String, dynamic> : {};

      if (users.containsKey(username)) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text('Username already exists. Please choose another.',
                  style: GoogleFonts.lato(color: Colors.white)),
            ]),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      // Save new user
      users[username] = password;
      await prefs.setString('cookify_users', json.encode(users));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text('Account created! You can now sign in.',
                style: GoogleFonts.lato(color: Colors.white)),
          ]),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      Navigator.of(context).pop(); // Go back to login
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B0000), Color(0xFFD32F2F), Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/cookify_logo.png',
                          fit: BoxFit.cover),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),

                  Text(
                    'Create Account',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  Text(
                    'Join Cookify today',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 32),

                  // Signup Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          _buildLabel('Username'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _usernameController,
                            hint: 'Choose a username',
                            icon: Icons.person_outline,
                            action: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter a username';
                              if (v.trim().length < 3) return 'Username must be at least 3 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password
                          _buildLabel('Password'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Create a password',
                            icon: Icons.lock_outline,
                            obscure: _obscurePassword,
                            action: TextInputAction.next,
                            onToggleObscure: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter a password';
                              if (v.trim().length < 4) return 'Password must be at least 4 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Confirm Password
                          _buildLabel('Confirm Password'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: 'Re-enter your password',
                            icon: Icons.lock_outline,
                            obscure: _obscureConfirm,
                            action: TextInputAction.done,
                            onSubmitted: (_) => _handleSignup(),
                            onToggleObscure: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please confirm your password';
                              if (v.trim() != _passwordController.text.trim()) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Signup Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFFD32F2F).withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text('Create Account',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Back to login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ',
                                  style: GoogleFonts.lato(
                                      fontSize: 13, color: Colors.black54)),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Text('Sign In',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD32F2F),
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.15),

                  const SizedBox(height: 24),
                  Text('🍳  Cookify — Cook Smart, Eat Well',
                      style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.montserrat(
            fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onToggleObscure,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      style: GoogleFonts.lato(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.lato(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
