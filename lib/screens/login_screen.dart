import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); // Email or Username
  final _emailController = TextEditingController();      // Only for signup
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
    if (_isLogin) {
      // ─── LOGIN LOGIC ──────────────────────────────────────────────────────
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text.trim();

      if (identifier.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await _authService.signIn(identifier, password);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar(e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // ─── SIGNUP LOGIC ─────────────────────────────────────────────────────
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim();
      final phone = _phoneController.text.trim();

      if (email.isEmpty || password.isEmpty || name.isEmpty || username.isEmpty || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await _authService.register(
          email: email,
          password: password,
          name: name,
          username: username,
          phone: phone,
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar(e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
              const SizedBox(height: 40),
              
              if (_isLogin) ...[
                // ─── LOGIN FIELDS ───────────────────────────────────────────
                _buildTextField(
                  controller: _identifierController,
                  label: 'Email or Username',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
              ] else ...[
                // ─── SIGNUP FIELDS ──────────────────────────────────────────
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
              ],
              
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
                    'https://auth.expo.io/@community/google.png',
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
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            filled: true,
            fillColor: Colors.grey[500]!.withOpacity(0.05),
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
