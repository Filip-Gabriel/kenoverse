import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/auth_service.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String username = '';
  String error = '';
  bool loading = false;
  bool isRegistering = false; // Toggle between Login and Register
  bool obscurePassword = true; // Toggle password visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: context.paddingXL,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              context.gapXL,
              Text(
                'Kenoverse',
                style: context.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.primary,
                ),
              ),
              context.gapLG,
              Text(
                isRegistering ? 'Create Account' : 'Welcome Back',
                style: context.textTheme.titleMedium,
              ),
              context.gapXL,
              if (isRegistering) ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter a username' : null,
                  onChanged: (val) => setState(() => username = val),
                ),
                context.gapLG,
              ],
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) => setState(() => email = val),
              ),
              context.gapLG,
              TextFormField(
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                onChanged: (val) => setState(() => password = val),
              ),
              context.gapXL,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => loading = true);
                      dynamic result;
                      if (isRegistering) {
                        result = await _auth.registerWithEmailAndPassword(email, password, username);
                      } else {
                        result = await _auth.signInWithEmailAndPassword(email, password);
                      }
                      
                      if (result == null) {
                        if (mounted) {
                          setState(() {
                            error = isRegistering 
                              ? 'Could not register with those credentials' 
                              : 'Could not sign in with those credentials';
                            loading = false;
                          });
                        }
                      } else {
                        if (mounted) {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                            );
                          }
                        }
                      }
                    }
                  },
                  child: loading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isRegistering ? 'Register' : 'Sign In'),
                ),
              ),
              if (error.isNotEmpty) ...[
                context.gapMD,
                Text(
                  error,
                  style: TextStyle(color: context.colorScheme.error, fontSize: 14.0),
                ),
              ],
              context.gapMD,
              TextButton(
                onPressed: () {
                  setState(() {
                    isRegistering = !isRegistering;
                    error = '';
                  });
                },
                child: Text(isRegistering 
                  ? 'Already have an account? Sign In' 
                  : 'New here? Create an Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
