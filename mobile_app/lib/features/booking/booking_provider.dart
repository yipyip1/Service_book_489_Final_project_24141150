import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BookingProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:5000/api/bookings';
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>> createPaymentIntent(double totalAmount) async {
    final token = await _storage.read(key: 'jwt');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/payments/intent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'amount': totalAmount}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create payment intent');
    }
  }

  Future<void> createBooking(String serviceId, DateTime startTime, double totalAmount, String stripePaymentIntentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) throw Exception('Not authenticated');

      final endTime = startTime.add(const Duration(hours: 1));

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceId': serviceId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'totalAmount': totalAmount,
          'notes': 'Booked via Flutter Mobile App',
          'stripePaymentIntentId': stripePaymentIntentId,
          'paymentStatus': 'paid'
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create booking: ${response.body}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
