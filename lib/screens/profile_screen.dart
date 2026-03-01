import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _authService = AuthService();
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? _buildGuestView(context)
          : FutureBuilder<dynamic>(
              future: _authService.getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.red));
                }

                final userData = snapshot.hasData ? snapshot.data!.data() : null;
                final String name = userData?['displayName'] ?? 'User';
                final bool isPremium = userData?['isPremium'] ?? false;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPremium ? '💎 Premium Member' : 'Standard User',
                        style: TextStyle(
                          color: isPremium ? Colors.amber[800] : Colors.grey,
                          fontWeight:
                              isPremium ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () async {
                          await _authService.signOut();
                          Navigator.pop(context); // Go back to Home
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person_outline, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Guest User',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text(
              'Sign in to sync your bookmarks and customize your experience.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text('Log In / Sign Up'),
          ),
        ],
      ),
    );
  }
}
