import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/brutalist_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/discovery/services_provider.dart';
import 'features/discovery/browse_services_screen.dart';
import 'features/booking/booking_provider.dart';

void main() {
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
          return MaterialApp(
            title: 'Service Booking Brutalist',
            debugShowCheckedModeBanner: false,
            theme: BrutalistTheme.themeData,
            home: authProvider.isAuthenticated 
                ? const BrowseServicesScreen() 
                : const AuthScreen(),
          );
        }
      ),
    );
  }
}
