import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/brutalist_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/discovery/services_provider.dart';
import 'features/booking/booking_provider.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

import 'features/admin/admin_dashboard_screen.dart';
import 'features/discovery/customer_home_screen.dart';
import 'features/discovery/provider_home_screen.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51TQ6rdRz5f8INEG1zEwuwiPOS7XbpfNvyAIY6f5WKngPnC0ZgZ70KpZCJEhMm4zWAOmpLJr1fOwGOVlbd20P7XrF009pPpFMzK';
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          Widget homeScreen = const AuthScreen();
          if (authProvider.isAuthenticated) {
            if (authProvider.role == 'admin') {
              homeScreen = const AdminDashboardScreen();
            } else if (authProvider.role == 'provider') {
              homeScreen = const ProviderHomeScreen();
            } else {
              homeScreen = const CustomerHomeScreen();
            }
          }

          return MaterialApp(
            title: 'Service Booking Brutalist',
            debugShowCheckedModeBanner: false,
            theme: BrutalistTheme.themeData,
            home: homeScreen,
          );
        }
      ),
    );
  }
}

