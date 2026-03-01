import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isLogin = true;

  void _showErrorSnackBar(Object e) {
    String errorMessage = e.toString();
    if (errorMessage.contains(']')) {
      errorMessage = errorMessage.split(']').last.trim();
    }
    if (errorMessage.isEmpty || errorMessage.length < 3) {
      errorMessage = "Error occurred. Please try again.";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.signInWithEmail(email, password);
      } else {
        await _authService.registerWithEmail(email, password);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin 
                    ? 'Log in to your account and keep tracking news.' 
                    : 'Join News Tracker and stay updated with live news.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 50),
              
              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              
              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              
              const SizedBox(height: 40),
              
              // Auth Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        _isLogin ? 'LOG IN' : 'SIGN UP',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Google Sign In Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Image.network(
                    'https://auth.expo.io/@community/google.png', // Reliable PNG logo
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, size: 20),
                  ),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Toggle Login/Signup
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin 
                      ? "New user? Create an account" 
                      : "Already have an account? Log in",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
