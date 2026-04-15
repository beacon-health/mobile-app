import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _signInWithProvider(OAuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          provider,
          redirectTo: _redirectUri(),
        );
      } else {
        await _supabase.auth.signInWithOAuth(provider);
      }
      // Navigation handled by AuthGate on auth state changes
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _redirectUri() {
    // For mobile, supabase_flutter uses app links. Default scheme: io.supabase.flutter
    // If you have custom scheme configured, update accordingly or pull from env.
    if (kIsWeb) {
      // On web, use current origin for redirect
      return Uri.base.replace(path: '/').toString();
    }
    return 'io.supabase.flutter://login-callback';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE6DD),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7F5), Color(0xFFDCE6DD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 32),
                          Image.asset('assets/beacon-logo.png', width: 240),
                          const SizedBox(height: 160),
                          SizedBox(
                            width: double.infinity,
                            child: SignInButton(
                              Buttons.Google,
                              text: "Continue with Google",
                              onPressed: _isLoading
                                  ? () {}
                                  : () {
                                      _signInWithProvider(OAuthProvider.google);
                                    },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SignInButton(
                              Buttons.Apple,
                              text: "Continue with Apple",
                              onPressed: _isLoading
                                  ? () {}
                                  : () {
                                      _signInWithProvider(OAuthProvider.apple);
                                    },
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: Colors.black26)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(color: Colors.black26)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const MainNavBar(
                                                    isGuest: true)),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: AppTheme.paynesGray,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              child: const Text("Continue as Guest"),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          const Text.rich(
                            TextSpan(
                              text: "By clicking continue, you agree to our ",
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: "Terms of Service",
                                  style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading ? null : () {},
                            child: const Text(
                              "Select a language 🌐",
                              style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
