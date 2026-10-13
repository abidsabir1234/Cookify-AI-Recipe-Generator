import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipe_app/main.dart';
import 'package:recipe_app/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Hardcoded default admin credentials
  static const String _defaultUsername = 'cookify';
  static const String _defaultPassword = '91125';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    // Check default credentials first
    bool authenticated = (username == _defaultUsername && password == _defaultPassword);

    // Then check saved user accounts
    if (!authenticated) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? usersJson = prefs.getString('cookify_users');
        if (usersJson != null) {
          final Map<String, dynamic> users =
              json.decode(usersJson) as Map<String, dynamic>;
          authenticated = users.containsKey(username) && users[username] == password;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (authenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Invalid username or password.',
                  style: GoogleFonts.lato(color: Colors.white)),
            ),
          ]),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _goToSignup() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
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
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5), width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/cookify_logo.png',
                          fit: BoxFit.cover),
                    ),
                  ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 14),

                  Text(
                    'Cookify',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 180.ms).slideY(begin: -0.2),

                  Text(
                    'Your smart kitchen assistant',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ).animate().fadeIn(delay: 280.ms),

                  const SizedBox(height: 30),

                  // ── Login Card ──────────────────────────────────────────
                  Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
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
                          // Header
                          Text('Welcome back 👋',
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A1A))),
                          const SizedBox(height: 2),
                          Text('Sign in to continue',
                              style: GoogleFonts.lato(
                                  fontSize: 13, color: Colors.black45)),

                          const SizedBox(height: 20),

                          // Username
                          _buildLabel('Username'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usernameController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.lato(fontSize: 14),
                            decoration: _inputDecoration(
                                'Enter your username', Icons.person_outline),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Password
                          _buildLabel('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            style: GoogleFonts.lato(fontSize: 14),
                            decoration: _inputDecoration(
                              'Enter your password',
                              Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.black38,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 22),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFFD32F2F).withValues(alpha: 0.55),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                                shadowColor:
                                    const Color(0xFFD32F2F).withValues(alpha: 0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text('Sign In',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3)),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Divider
                          Row(children: [
                            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('or',
                                  style: GoogleFonts.lato(
                                      fontSize: 12, color: Colors.black38)),
                            ),
                            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                          ]),

                          const SizedBox(height: 14),

                          // Sign Up Button (outlined)
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: _goToSignup,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD32F2F),
                                side: const BorderSide(
                                    color: Color(0xFFD32F2F), width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Create an Account',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2)),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Already have account link
                          Center(
                            child: GestureDetector(
                              onTap: _goToSignup,
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.lato(
                                      fontSize: 13, color: Colors.black45),
                                  children: [
                                    const TextSpan(text: "Don't have an account? "),
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFD32F2F),
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.12),

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

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2D2D)),
      );

  InputDecoration _inputDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lato(color: Colors.black38, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5)),
    );
  }
}
