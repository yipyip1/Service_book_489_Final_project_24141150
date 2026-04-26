import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_button.dart';
import '../../core/widgets/brutalist_text_field.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        _profile = jsonDecode(res.body);
        _nameCtrl.text = _profile['fullName'] ?? '';
        _phoneCtrl.text = _profile['phoneNumber'] ?? '';
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      final body = <String, String>{
        'fullName': _nameCtrl.text,
        'phoneNumber': _phoneCtrl.text,
      };
      if (_passwordCtrl.text.isNotEmpty) {
        body['password'] = _passwordCtrl.text;
      }

      final res = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        _passwordCtrl.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PROFILE UPDATED SUCCESSFULLY')),
          );
        }
      } else {
        throw Exception('Update failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PROFILE', style: Theme.of(context).textTheme.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: BrutalistTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: BrutalistTheme.primary,
                        border: Border.all(color: BrutalistTheme.primary, width: BrutalistTheme.borderWidth),
                      ),
                      child: Center(
                        child: Text(
                          (_profile['fullName'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: BrutalistTheme.surface),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: BrutalistTheme.primary, width: 2),
                      ),
                      child: Text(
                        (_profile['role'] ?? 'USER').toString().toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: BrutalistTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _profile['email'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(height: BrutalistTheme.borderWidth, color: BrutalistTheme.primary),
                  const SizedBox(height: 32),

                  Text('EDIT PROFILE', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 16),
                  BrutalistTextField(label: 'Full Name', controller: _nameCtrl),
                  const SizedBox(height: 16),
                  BrutalistTextField(label: 'Phone Number', controller: _phoneCtrl, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  BrutalistTextField(label: 'New Password (leave blank to keep)', controller: _passwordCtrl, isPassword: true),
                  const SizedBox(height: 32),
                  BrutalistButton(
                    text: 'SAVE CHANGES',
                    isLoading: _isSaving,
                    onPressed: _updateProfile,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Member since ${_profile['createdAt']?.toString().split('T').first ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
