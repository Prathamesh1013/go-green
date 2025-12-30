import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showPassword = false;
  String _loginMethod = 'phone'; 

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Getcaregir',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'On-Ground Manager',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFDBEAFE),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _methodButton('Phone', LucideIcons.phone, _loginMethod == 'phone', () => setState(() => _loginMethod = 'phone'))),
                        const SizedBox(width: 8),
                        Expanded(child: _methodButton('Email', LucideIcons.mail, _loginMethod == 'email', () => setState(() => _loginMethod = 'email'))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _identifierController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(_loginMethod == 'phone' ? LucideIcons.phone : LucideIcons.mail, color: Colors.grey),
                        hintText: _loginMethod == 'phone' ? 'Phone Number' : 'Email Address',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.grey),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        hintText: 'Password',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('Login button pressed');
                        context.read<AppProvider>().login();
                      },
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryBlue))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppTheme.primaryBlue : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
