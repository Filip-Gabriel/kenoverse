// A dialog for managing user preferences and account settings.
// Allows users to update their username, toggle theme modes, and sign out.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kenoverse/functionality/auth_service.dart';
import 'package:kenoverse/screens/login_screen.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'package:provider/provider.dart';
import 'package:kenoverse/functionality/theme/theme_notifier.dart';
import 'package:kenoverse/functionality/firestore_service.dart';
import 'package:kenoverse/functionality/theme/app_constants.dart';
import 'package:kenoverse/screens/liked_songs_screen.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;
  final _usernameController = TextEditingController();

  bool _isUsernameSet = false;
  String _username = '';
  int? _userNumber;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _loadUserData();
    }
  }

  void _loadUserData() async {
    Map<String, dynamic>? data = await _firestoreService.getUserData(user!.uid);
    if (mounted && data != null) {
      setState(() {
        _usernameController.text = data['username'] ?? '';
        _username = data['username'] ?? '';
        _userNumber = data['userNumber'];
        _isUsernameSet = _username.isNotEmpty;
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
    return Dialog(
      insetPadding: context.paddingXL,
      shape: RoundedRectangleBorder(borderRadius: context.radiusLG),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: context.paddingMD,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: context.paddingVertical(AppConstants.spacingMD),
                children: [
                  _buildProfileHeader(),
                  const Divider(indent: 20, endIndent: 20),
                  _buildSectionHeader('Account'),
                  if (user != null && !_isUsernameSet)
                    Padding(
                      padding: context.paddingHorizontal(AppConstants.spacingMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Set Username',
                                hintText: 'Enter a username',
                                isDense: true,
                              ),
                            ),
                          ),
                          context.gapMD,
                          ElevatedButton(
                            onPressed: () async {
                              if (_usernameController.text.isNotEmpty) {
                                await _firestoreService.updateUsername(user!.uid, _usernameController.text);
                                _loadUserData(); // Reload to get the number
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username set!')));
                                }
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(user?.email ?? 'Not logged in'),
                  ),
                  if (user == null)
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Sign In'),
                      onTap: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                  const Divider(indent: 20, endIndent: 20),
                  _buildSectionHeader('Appearance'),
                  Consumer<ThemeNotifier>(
                    builder: (context, themeNotifier, child) {
                      return RadioGroup<ThemeMode>(
                        groupValue: themeNotifier.themeMode,
                        onChanged: (mode) => themeNotifier.setThemeMode(mode!),
                        child: const Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              title: Text('Follow System'),
                              value: ThemeMode.system,
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text('Light Mode'),
                              value: ThemeMode.light,
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text('Dark Mode'),
                              value: ThemeMode.dark,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  _buildSectionHeader('Library'),
                  ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: const Text('Liked Songs'),
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LikedSongsScreen()),
                      );
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  _buildSectionHeader('Support & About'),
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: const Text('Send Feedback'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () {},
                  ),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    trailing: Text('1.0.0'),
                  ),
                  if (user != null) ...[
                    const Divider(indent: 20, endIndent: 20),
                    Padding(
                      padding: context.paddingMD,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _auth.signOut();
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: context.paddingVertical(AppConstants.spacingMD),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: context.paddingVertical(AppConstants.spacingLG),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: context.colorScheme.primaryContainer,
            child: Icon(
              user == null ? Icons.login : Icons.person_outline,
              size: 40,
              color: context.colorScheme.onPrimaryContainer,
            ),
          ),
          context.gapMD,
          Text(
            user == null ? 'Not logged in' : (_username.isNotEmpty ? _username : 'User'),
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (user != null && _userNumber != null)
            Text(
              'Nekovert #$_userNumber',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.secondary.withValues(alpha: 0.7),
              ),
            ),
          if (user != null && _username.isEmpty)
            Text(
              'Username not set',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: context.colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
