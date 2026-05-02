import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kenoverse/functionality/auth_service.dart';
import 'package:kenoverse/screens/login_screen.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final AuthService _auth = AuthService();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user != null ? 'Logged in as' : 'Not logged in'),
            subtitle: Text(user?.email ?? 'Sign in to sync your data'),
            trailing: user != null
                ? TextButton(
                    onPressed: () async {
                      await _auth.signOut();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  )
                : TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text('Sign In'),
                  ),
          ),
          const Divider(),
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: context.isDarkMode,
            onChanged: (bool value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme switching coming soon!')),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Developer'),
            subtitle: const Text('Monarch'),
            onTap: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomBar.bottomAppBar(context),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
