import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_card.dart';
import '../auth/auth_provider.dart';
import 'add_service_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _myServices = [];
  List<dynamic> _myBookings = [];
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingNotifications = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProviderData();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProviderData() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      // Fetch both services and bookings in parallel
      final results = await Future.wait([
        http.get(
          Uri.parse('http://10.0.2.2:5000/api/services/my-services'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('http://10.0.2.2:5000/api/bookings/provider-bookings'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      if (results[0].statusCode == 200) {
        _myServices = jsonDecode(results[0].body);
      }
      if (results[1].statusCode == 200) {
        _myBookings = jsonDecode(results[1].body);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoadingNotifications = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        _notifications = jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if(mounted) setState(() => _isLoadingNotifications = false);
    }
  }

  Future<void> _markNotificationRead(String id) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      await http.put(
        Uri.parse('http://10.0.2.2:5000/api/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      _fetchNotifications();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showNotificationInbox() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('INBOX', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: BrutalistTheme.primary, width: 2)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _isLoadingNotifications 
            ? const Center(child: CircularProgressIndicator(color: BrutalistTheme.primary))
            : _notifications.isEmpty 
              ? const Center(child: Text('NO NEW NOTIFICATIONS'))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(color: BrutalistTheme.primary, thickness: 2),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isRead = notif['isRead'] == true;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread, color: isRead ? Colors.grey : BrutalistTheme.primary),
                      title: Text(notif['message'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, color: isRead ? Colors.grey : BrutalistTheme.primary)),
                      subtitle: Text(notif['createdAt'].toString().split('T').first),
                      onTap: () {
                        if (!isRead) _markNotificationRead(notif['_id']);
                      },
                    );
                  },
                ),
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

  Future<void> _processRefund(String bookingId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');

      final res = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/payments/refund/$bookingId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        _fetchProviderData();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund Processed')));
      } else {
        throw Exception('Refund failed');
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildServicesTab() {
    if (_myServices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Text('NO SERVICES PUBLISHED YET.\nTAP + TO ADD ONE.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: BrutalistTheme.primary)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: _myServices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final service = _myServices[index];
        return BrutalistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (service['imageUrl'] != null && service['imageUrl'].toString().isNotEmpty)
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: BrutalistTheme.primary, width: BrutalistTheme.borderWidth),
                    image: DecorationImage(
                      image: NetworkImage('http://10.0.2.2:5000${service['imageUrl']}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (service['imageUrl'] != null && service['imageUrl'].toString().isNotEmpty)
                const SizedBox(height: 12),
              Text(service['title']?.toString().toUpperCase() ?? 'N/A', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('CATEGORY: ${service['category']?.toString().toUpperCase() ?? 'N/A'}', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(height: BrutalistTheme.borderWidth, color: BrutalistTheme.primary),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PRICE', style: Theme.of(context).textTheme.labelLarge),
                  Text('\$${service['price']}', style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CONTACT', style: Theme.of(context).textTheme.labelLarge),
                  Text(service['contactNumber']?.toString() ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    if (_myBookings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Text('NO BOOKINGS YET.\nCUSTOMERS WILL APPEAR HERE.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: BrutalistTheme.primary)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: _myBookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final booking = _myBookings[index];
        final customer = booking['customerId'] ?? {};
        final service = booking['serviceId'] ?? {};
        final dateStr = booking['startTime'] ?? '';
        final isPaid = booking['paymentStatus'] == 'paid';
        final isRefunded = booking['paymentStatus'] == 'refunded';

        return BrutalistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SERVICE: ${service['title']?.toUpperCase() ?? 'N/A'}', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text('CUSTOMER: ${customer['fullName']?.toUpperCase() ?? 'UNKNOWN'}', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('EMAIL: ${customer['email'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Container(height: BrutalistTheme.borderWidth, color: BrutalistTheme.primary),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AMOUNT PAID', style: Theme.of(context).textTheme.labelLarge),
                  Text('\$${booking['totalAmount']}', style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DATE', style: Theme.of(context).textTheme.labelLarge),
                  Text(dateStr.toString().split('T').first, style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isRefunded ? 'STATUS: REFUNDED' : 'STATUS: PAID', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: isRefunded ? BrutalistTheme.error : Colors.green)
                  ),
                  if (isPaid)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: BrutalistTheme.error, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: () => _processRefund(booking['_id']),
                      child: const Text('ISSUE REFUND', style: TextStyle(color: BrutalistTheme.error, fontWeight: FontWeight.bold)),
                    )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('PROVIDER DASH', style: Theme.of(context).textTheme.headlineLarge),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, size: 32),
                onPressed: _showNotificationInbox,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: BrutalistTheme.error, shape: BoxShape.circle),
                    child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 32),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: BrutalistTheme.primary,
          labelColor: BrutalistTheme.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'MY SERVICES (${_myServices.length})'),
            Tab(text: 'BOOKINGS (${_myBookings.length})'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: BrutalistTheme.primary))
          : RefreshIndicator(
              color: BrutalistTheme.primary,
              onRefresh: _fetchProviderData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildServicesTab(),
                  _buildBookingsTab(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BrutalistTheme.primary,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add, color: BrutalistTheme.surface),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddServiceScreen())).then((_) => _fetchProviderData());
        },
      ),
    );
  }
}
