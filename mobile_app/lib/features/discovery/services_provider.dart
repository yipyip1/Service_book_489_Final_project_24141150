import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServiceProvider with ChangeNotifier { 
  final String baseUrl = 'http://10.0.2.2:5000/api/services';
  
  List<dynamic> _services = [];
  bool _isLoading = false;

  List<dynamic> get services => _services;
  bool get isLoading => _isLoading;

  Future<void> fetchServices([String? category]) async {
    _isLoading = true;
    // We call notifyListeners asynchronously to avoid build conflicts
    Future.microtask(() => notifyListeners());

    try {
      String url = baseUrl;
      if (category != null && category.isNotEmpty) {
        url += '?category=$category';
      }
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        _services = jsonDecode(response.body);
      } else {
        throw Exception('Failed to load services');
      }
    } catch (error) {
      debugPrint("Error fetching services: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
