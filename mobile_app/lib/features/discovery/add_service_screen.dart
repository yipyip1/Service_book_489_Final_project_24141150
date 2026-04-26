import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final _contactCtrl = TextEditingController(); // New contact number
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitService() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PLEASE SELECT AN IMAGE')));
      return;
    }
    if (_contactCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PLEASE ADD A CONTACT NUMBER')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/api/services'));
      
      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Text Fields
      request.fields['title'] = _titleCtrl.text;
      request.fields['description'] = _descCtrl.text;
      request.fields['category'] = _categoryCtrl.text;
      request.fields['price'] = _priceCtrl.text.isEmpty ? '50.0' : _priceCtrl.text;
      request.fields['durationMinutes'] = _durationCtrl.text.isEmpty ? '60' : _durationCtrl.text;
      request.fields['contactNumber'] = _contactCtrl.text;
      
      // Image File
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

      final response = await request.send();

      if (response.statusCode == 201) {
        if(mounted) {
          // No need to fetch services here because ProviderDashboardScreen fetches provider bookings, not services directly. 
          // But it's good practice.
          context.read<ServiceProvider>().fetchServices();
          Navigator.pop(context);
        }
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception(respStr);
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: BrutalistTheme.surface,
                  border: Border.all(color: BrutalistTheme.primary, width: BrutalistTheme.borderWidth),
                  image: _selectedImage != null 
                    ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                    : null,
                ),
                child: _selectedImage == null 
                  ? const Center(child: Text('TAP TO UPLOAD IMAGE', style: TextStyle(fontWeight: FontWeight.bold, color: BrutalistTheme.primary)))
                  : null,
              ),
            ),
            const SizedBox(height: 24),
            BrutalistTextField(label: 'Service Title', controller: _titleCtrl),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Category (e.g. Cleaning)', controller: _categoryCtrl),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Contact Number', controller: _contactCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Price (\$)', controller: _priceCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Duration (Minutes)', controller: _durationCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            BrutalistTextField(label: 'Description', controller: _descCtrl),
            const SizedBox(height: 32),
            BrutalistButton(
              text: 'PUBLISH SERVICE',
              isLoading: _isLoading,
              onPressed: _submitService,
            )
          ],
        ),
      ),
    );
  }
}
