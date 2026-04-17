import 'package:flutter/material.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_button.dart';
import '../booking/confirm_booking_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final dynamic service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: BrutalistTheme.primary,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: BrutalistTheme.surface,
                      child: Text(
                        service['category'] ?? 'GENERAL',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: BrutalistTheme.primary, // Inverted thick border styling
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      service['title'].toString().toUpperCase(),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: BrutalistTheme.surface,
                        fontSize: 40,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROVIDER: ${service['providerId']?['fullName'] ?? 'UNKNOWN'}'.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    service['description'] ?? 'No description provided.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  // Brutalist Divider
                  Container(height: BrutalistTheme.borderWidth, color: BrutalistTheme.primary),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL COST', style: Theme.of(context).textTheme.labelLarge),
                      Text('\$${service['price']}', style: Theme.of(context).textTheme.headlineLarge),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('EST. DURATION', style: Theme.of(context).textTheme.labelLarge),
                      Text('${service['durationMinutes']} MINS', style: Theme.of(context).textTheme.headlineLarge),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BrutalistButton(
            text: 'BOOK APPOINTMENT',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ConfirmBookingScreen(service: service)),
              );
            },
          ),
        ),
      ),
    );
  }
}
