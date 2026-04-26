import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/brutalist_button.dart';
import '../../core/widgets/brutalist_text_field.dart';
import '../../core/theme/brutalist_theme.dart';
import 'auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // Only for registration
  String _selectedRole = 'customer'; // Default role

  void _submit() async {
    final provider = context.read<AuthProvider>();
    try {
      if (_isLogin) {
        await provider.login(_emailCtrl.text, _passwordCtrl.text);
      } else {
        await provider.register(_nameCtrl.text, _emailCtrl.text, _passwordCtrl.text, _selectedRole);
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(e.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
             backgroundColor: BrutalistTheme.error,
           )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'LOG IN' : 'REGISTER',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 16),
              Container(height: BrutalistTheme.borderWidth, color: BrutalistTheme.primary, width: 80),
              const SizedBox(height: 48),

              if (!_isLogin) ...[
                BrutalistTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: BrutalistTheme.surface,
                    border: Border.all(color: BrutalistTheme.outline, width: BrutalistTheme.borderWidth),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      dropdownColor: BrutalistTheme.surface,
                      items: const [
                        DropdownMenuItem(value: 'customer', child: Text('I AM A CUSTOMER', style: TextStyle(fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'provider', child: Text('I AM A SERVICE PROVIDER', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedRole = val!);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              BrutalistTextField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              BrutalistTextField(
                label: 'Password',
                controller: _passwordCtrl,
                isPassword: true,
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: BrutalistButton(
                  text: _isLogin ? 'ENTER PORTAL' : 'CREATE ACCOUNT',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: BrutalistButton(
                  text: _isLogin ? 'NEED AN ACCOUNT?' : 'ALREADY REGISTERED?',
                  isSecondary: true,
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
