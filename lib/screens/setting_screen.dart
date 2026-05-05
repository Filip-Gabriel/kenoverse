import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kenoverse/functionality/auth_service.dart';
import 'package:kenoverse/screens/login_screen.dart';
import 'package:kenoverse/functionality/bottom_app_bar.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:provider/provider.dart';
import 'package:kenoverse/functionality/theme/theme_notifier.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;
  final _usernameController = TextEditingController();

  bool _isUsernameSet = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _loadUsername();
    }
  }

  void _loadUsername() async {
    String? name = await _firestoreService.getUsername(user!.uid);
    if (name != null) {
      setState(() {
        _usernameController.text = name;
        _isUsernameSet = true;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

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
          if (user != null)
            Padding(
              padding: context.paddingHorizontal(AppConstants.spacingMD),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      enabled: !_isUsernameSet,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter a username',
                        suffixIcon: _isUsernameSet ? const Icon(Icons.lock_outline, size: 16) : null,
                        helperText: _isUsernameSet ? 'Username cannot be changed' : null,
                      ),
                    ),
                  ),
                  if (!_isUsernameSet) ...[
                    context.gapMD,
                    ElevatedButton(
                      onPressed: () async {
                        if (_usernameController.text.isNotEmpty) {
                          await _firestoreService.updateUsername(user!.uid, _usernameController.text);
                          if (mounted) {
                            setState(() => _isUsernameSet = true);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username set!')));
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ],
              ),
            ),
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
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Follow System'),
                    value: ThemeMode.system,
                    groupValue: themeNotifier.themeMode,
                    onChanged: (mode) => themeNotifier.setThemeMode(mode!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Mode'),
                    value: ThemeMode.light,
                    groupValue: themeNotifier.themeMode,
                    onChanged: (mode) => themeNotifier.setThemeMode(mode!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark Mode'),
                    value: ThemeMode.dark,
                    groupValue: themeNotifier.themeMode,
                    onChanged: (mode) => themeNotifier.setThemeMode(mode!),
                  ),
                ],
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
