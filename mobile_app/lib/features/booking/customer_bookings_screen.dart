import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_card.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  List<dynamic> _myBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/bookings/my-bookings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        _myBookings = jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      final res = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/bookings/$bookingId/cancel'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        _fetchBookings();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BOOKING CANCELLED')));
      } else {
        final body = jsonDecode(res.body);
        throw Exception(body['message']);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmServiceReceived(String bookingId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      final res = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/bookings/$bookingId/complete'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        _fetchBookings();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SERVICE MARKED AS COMPLETED')));
      } else {
        final body = jsonDecode(res.body);
        throw Exception(body['message']);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showInvoice(dynamic booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('TRANSACTION INVOICE'),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: BrutalistTheme.primary, width: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SERVICE: ${booking['serviceId']?['title'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('AMOUNT PAID: \$${booking['totalAmount']}'),
            const SizedBox(height: 8),
            Text('PAYMENT: ${booking['paymentStatus']?.toString().toUpperCase()}'),
            const SizedBox(height: 8),
            Text('STATUS: ${booking['status']?.toString().toUpperCase()}'),
            const SizedBox(height: 8),
            Text('DATE: ${booking['startTime']?.toString().split('T').first}'),
            const SizedBox(height: 16),
            Container(height: 2, color: BrutalistTheme.primary),
            const SizedBox(height: 16),
            const Text('PAID VIA STRIPE SECURE GATEWAY', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: BrutalistTheme.primary, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return BrutalistTheme.error;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.verified;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildTimeline(String status) {
    final steps = ['BOOKED', 'PENDING', 'COMPLETED'];
    int activeStep;
    bool isCancelled = status == 'cancelled';

    if (isCancelled) {
      activeStep = -1; // No step active
    } else if (status == 'completed') {
      activeStep = 2;
    } else if (status == 'confirmed') {
      activeStep = 1;
    } else {
      activeStep = 1; // pending
    }

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = !isCancelled && index <= activeStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? Colors.grey.shade300
                            : isActive
                                ? BrutalistTheme.primary
                                : Colors.grey.shade300,
                        shape: BoxShape.rectangle,
                        border: Border.all(color: BrutalistTheme.primary, width: 2),
                      ),
                      child: Center(
                        child: isActive
                            ? const Icon(Icons.check, size: 16, color: BrutalistTheme.surface)
                            : Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCancelled && index == 1 ? 'CANCELLED' : steps[index],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isCancelled
                            ? BrutalistTheme.error
                            : isActive
                                ? BrutalistTheme.primary
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCancelled
                        ? Colors.grey.shade300
                        : (index < activeStep ? BrutalistTheme.primary : Colors.grey.shade300),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MY BOOKINGS', style: Theme.of(context).textTheme.headlineLarge),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: BrutalistTheme.primary))
          : _myBookings.isEmpty
              ? const Center(child: Text('NO BOOKINGS YET', style: TextStyle(fontWeight: FontWeight.bold, color: BrutalistTheme.primary)))
              : RefreshIndicator(
                  color: BrutalistTheme.primary,
                  onRefresh: _fetchBookings,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: _myBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final booking = _myBookings[index];
                      final status = booking['status'] ?? 'pending';
                      final paymentStatus = booking['paymentStatus'] ?? 'pending';
                      final isPending = status == 'pending' || status == 'confirmed';

                      return BrutalistCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Title
                            Text(
                              booking['serviceId']?['title']?.toString().toUpperCase() ?? 'SERVICE',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            Text('DATE: ${booking['startTime']?.toString().split('T').first}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Text('AMOUNT: \$${booking['totalAmount']}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 16),

                            // Timeline
                            Container(height: BrutalistTheme.borderWidth, color: BrutalistTheme.primary),
                            const SizedBox(height: 16),
                            _buildTimeline(status),
                            const SizedBox(height: 16),
                            Container(height: BrutalistTheme.borderWidth, color: BrutalistTheme.primary),
                            const SizedBox(height: 12),

                            // Status + Payment badges
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    border: Border.all(color: BrutalistTheme.primary, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_statusIcon(status), size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: paymentStatus == 'refunded' ? BrutalistTheme.error : Colors.green,
                                    border: Border.all(color: BrutalistTheme.primary, width: 1),
                                  ),
                                  child: Text(paymentStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Action buttons
                            Row(
                              children: [
                                // Invoice button — always available
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: BrutalistTheme.primary, width: 2),
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    ),
                                    onPressed: () => _showInvoice(booking),
                                    child: const Text('INVOICE', style: TextStyle(color: BrutalistTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                                // Confirm Service Received — only for pending bookings
                                if (isPending) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.green, width: 2),
                                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      ),
                                      onPressed: () => _confirmServiceReceived(booking['_id']),
                                      child: const Text('GOT SERVICE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                ],
                                // Cancel — only for pending bookings
                                if (isPending) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: BrutalistTheme.error, width: 2),
                                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('CANCEL BOOKING?'),
                                            content: const Text('Are you sure you want to cancel this booking?'),
                                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: BrutalistTheme.primary, width: 2)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('NO', style: TextStyle(color: BrutalistTheme.primary)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _cancelBooking(booking['_id']);
                                                },
                                                child: const Text('YES, CANCEL', style: TextStyle(color: BrutalistTheme.error, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Text('CANCEL', style: TextStyle(color: BrutalistTheme.error, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
