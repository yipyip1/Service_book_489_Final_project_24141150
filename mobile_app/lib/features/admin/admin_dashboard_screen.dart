import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_card.dart';
import '../auth/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _users = [];
  List<dynamic> _bookings = [];
  List<dynamic> _services = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');
      final headers = {'Authorization': 'Bearer $token'};

      final results = await Future.wait([
        http.get(Uri.parse('http://10.0.2.2:5000/api/admin/users'), headers: headers),
        http.get(Uri.parse('http://10.0.2.2:5000/api/admin/bookings'), headers: headers),
        http.get(Uri.parse('http://10.0.2.2:5000/api/admin/analytics'), headers: headers),
        http.get(Uri.parse('http://10.0.2.2:5000/api/services'), headers: headers),
      ]);

      if (results[0].statusCode == 200) _users = jsonDecode(results[0].body);
      if (results[1].statusCode == 200) _bookings = jsonDecode(results[1].body);
      if (results[2].statusCode == 200) _analytics = jsonDecode(results[2].body);
      if (results[3].statusCode == 200) _services = jsonDecode(results[3].body);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBan(String userId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');
      await http.put(
        Uri.parse('http://10.0.2.2:5000/api/admin/users/$userId/ban'),
        headers: {'Authorization': 'Bearer $token'},
      );
      _fetchAllData();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ─── USERS TAB ───
  Widget _buildUsersTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final user = _users[index];
        final isBanned = user['isBanned'] == true;

        return BrutalistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(user['fullName'].toString().toUpperCase(), style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: user['role'] == 'provider' ? Colors.blue : Colors.teal,
                    child: Text(user['role'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(user['email'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
              if (isBanned)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('⛔ BANNED', style: TextStyle(color: BrutalistTheme.error, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 12),
              if (user['role'] != 'admin')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isBanned ? Colors.green : BrutalistTheme.error, width: 2),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => _toggleBan(user['_id']),
                    child: Text(
                      isBanned ? 'UNBAN USER' : 'BAN USER',
                      style: TextStyle(color: isBanned ? Colors.green : BrutalistTheme.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── BOOKINGS TAB ───
  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return const Center(child: Text('NO BOOKINGS YET', style: TextStyle(fontWeight: FontWeight.bold, color: BrutalistTheme.primary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: _bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final customer = booking['customerId'] ?? {};
        final service = booking['serviceId'] ?? {};
        final status = booking['status'] ?? 'pending';
        final paymentStatus = booking['paymentStatus'] ?? 'pending';

        Color statusColor;
        switch (status) {
          case 'completed': statusColor = Colors.green; break;
          case 'cancelled': statusColor = BrutalistTheme.error; break;
          case 'confirmed': statusColor = Colors.blue; break;
          default: statusColor = Colors.orange;
        }

        return BrutalistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service['title']?.toString().toUpperCase() ?? 'N/A', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text('CUSTOMER: ${customer['fullName'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
              Text('EMAIL: ${customer['email'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Container(height: BrutalistTheme.borderWidth, color: BrutalistTheme.primary),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AMOUNT', style: Theme.of(context).textTheme.labelLarge),
                  Text('\$${booking['totalAmount']}', style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DATE', style: Theme.of(context).textTheme.labelLarge),
                  Text(booking['startTime']?.toString().split('T').first ?? '', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: statusColor,
                    child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: paymentStatus == 'refunded' ? BrutalistTheme.error : paymentStatus == 'paid' ? Colors.green : Colors.orange,
                    child: Text(paymentStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── ANALYTICS TAB ───
  Widget _buildStatCard(String label, dynamic value, {Color color = BrutalistTheme.primary, IconData? icon}) {
    return BrutalistCard(
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: BrutalistTheme.primary));
    }

    final bookingsByStatus = _analytics['bookingsByStatus'] ?? {};
    final paymentStats = _analytics['paymentStats'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── PLATFORM OVERVIEW ──
          Text('PLATFORM OVERVIEW', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('USERS', _analytics['totalUsers'] ?? 0, icon: Icons.people)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('SERVICES', _analytics['totalServices'] ?? 0, icon: Icons.home_repair_service)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('CUSTOMERS', _analytics['totalCustomers'] ?? 0, icon: Icons.person, color: Colors.teal)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('PROVIDERS', _analytics['totalProviders'] ?? 0, icon: Icons.engineering, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 32),

          // ── REVENUE ──
          Text('REVENUE OVERVIEW', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          _buildStatCard('TOTAL REVENUE', '\$${(_analytics['totalRevenue'] ?? 0).toStringAsFixed(2)}', icon: Icons.attach_money, color: Colors.green),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('REFUNDED', '\$${(_analytics['totalRefunded'] ?? 0).toStringAsFixed(2)}', color: BrutalistTheme.error, icon: Icons.money_off)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('NET', '\$${(_analytics['netRevenue'] ?? 0).toStringAsFixed(2)}', color: Colors.green, icon: Icons.trending_up)),
            ],
          ),
          const SizedBox(height: 32),

          // ── BOOKING BREAKDOWN ──
          Text('BOOKING STATUS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('TOTAL', _analytics['totalBookings'] ?? 0, icon: Icons.calendar_month)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('PENDING', bookingsByStatus['pending'] ?? 0, color: Colors.orange, icon: Icons.hourglass_top)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('COMPLETED', bookingsByStatus['completed'] ?? 0, color: Colors.green, icon: Icons.verified)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('CANCELLED', bookingsByStatus['cancelled'] ?? 0, color: BrutalistTheme.error, icon: Icons.cancel)),
            ],
          ),
          const SizedBox(height: 32),

          // ── PAYMENT BREAKDOWN ──
          Text('PAYMENT STATUS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('PAID', paymentStats['paid'] ?? 0, color: Colors.green, icon: Icons.check_circle)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('REFUNDED', paymentStats['refunded'] ?? 0, color: BrutalistTheme.error, icon: Icons.undo)),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── SERVICES TAB ───
  Future<void> _deleteService(String serviceId) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt');
      final res = await http.delete(
        Uri.parse('http://10.0.2.2:5000/api/admin/services/$serviceId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _fetchAllData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SERVICE DELETED')));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _buildServicesTab() {
    if (_services.isEmpty) {
      return const Center(child: Text('NO SERVICES YET', style: TextStyle(fontWeight: FontWeight.bold, color: BrutalistTheme.primary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: _services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final service = _services[index];
        final provider = service['providerId'];
        return BrutalistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (service['imageUrl'] != null && service['imageUrl'].toString().isNotEmpty)
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: BrutalistTheme.primary, width: BrutalistTheme.borderWidth),
                    image: DecorationImage(
                      image: NetworkImage('http://10.0.2.2:5000${service['imageUrl']}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (service['imageUrl'] != null) const SizedBox(height: 8),
              Text(service['title']?.toString().toUpperCase() ?? 'N/A', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text('CATEGORY: ${service['category'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
              Text('PRICE: \$${service['price']}', style: Theme.of(context).textTheme.bodyMedium),
              if (provider != null)
                Text('PROVIDER: ${provider['fullName'] ?? provider['email'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: BrutalistTheme.error, width: 2),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('DELETE SERVICE?'),
                        content: Text('Remove "${service['title']}" permanently?'),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: BrutalistTheme.primary, width: 2)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('NO', style: TextStyle(color: BrutalistTheme.primary))),
                          TextButton(
                            onPressed: () { Navigator.pop(context); _deleteService(service['_id']); },
                            child: const Text('YES, DELETE', style: TextStyle(color: BrutalistTheme.error, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('DELETE SERVICE', style: TextStyle(color: BrutalistTheme.error, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ADMIN', style: Theme.of(context).textTheme.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: BrutalistTheme.primary,
          labelColor: BrutalistTheme.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'USERS'),
            Tab(text: 'BOOKINGS'),
            Tab(text: 'SERVICES'),
            Tab(text: 'ANALYTICS'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: BrutalistTheme.primary))
          : RefreshIndicator(
              color: BrutalistTheme.primary,
              onRefresh: _fetchAllData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTab(),
                  _buildBookingsTab(),
                  _buildServicesTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
    );
  }
}
