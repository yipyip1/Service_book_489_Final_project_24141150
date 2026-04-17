import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_button.dart';
import '../../core/widgets/brutalist_text_field.dart';
import 'services_provider.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitService() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');
      
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': _titleCtrl.text,
          'description': _descCtrl.text,
          'category': _categoryCtrl.text,
          'price': double.tryParse(_priceCtrl.text) ?? 50.0,
          'durationMinutes': int.tryParse(_durationCtrl.text) ?? 60,
        }),
      );

      if (response.statusCode == 201) {
        if(mounted) {
          context.read<ServiceProvider>().fetchServices();
          Navigator.pop(context);
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NEW SERVICE', style: Theme.of(context).textTheme.headlineLarge)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            BrutalistTextField(label: 'Service Title', controller: _titleCtrl),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Category (e.g. Cleaning)', controller: _categoryCtrl),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Price (\$)', controller: _priceCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Duration (Minutes)', controller: _durationCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Description', controller: _descCtrl),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: BrutalistButton(
                text: 'PUBLISH SERVICE',
                isLoading: _isLoading,
                onPressed: _submitService,
              ),
            )
          ],
        ),
      ),
    );
  }
}
