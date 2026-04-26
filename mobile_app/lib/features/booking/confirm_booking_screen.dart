import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_button.dart';
import '../../core/widgets/brutalist_card.dart';
import '../../core/services/notification_service.dart';
import 'booking_provider.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final dynamic service;

  const ConfirmBookingScreen({super.key, required this.service});

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: BrutalistTheme.primary,
              onPrimary: BrutalistTheme.surface,
              surface: BrutalistTheme.surface,
            ),
             // Forcing brutalist squares onto the date picker
            dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _confirmBooking() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PLEASE SELECT A DATE FIRST')),
      );
      return;
    }

    final provider = context.read<BookingProvider>();
    final amount = (widget.service['price'] as num).toDouble();
    
    try {
      // 1. Create Payment Intent
      final intentData = await provider.createPaymentIntent(amount);
      final clientSecret = intentData['paymentIntent'];
      final paymentIntentId = intentData['id'];

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Stitch Professional Service',
          style: ThemeMode.dark, // Brutalist style
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. If success, Create Booking
      await provider.createBooking(
        widget.service['_id'], 
        _selectedDate!, 
        amount,
        paymentIntentId
      );

      // 5. Schedule Local Notification 2 hours before
      final reminderTime = _selectedDate!.subtract(const Duration(hours: 2));
      if (reminderTime.isAfter(DateTime.now())) {
        await NotificationService().scheduleNotification(
          id: widget.service['_id'].hashCode,
          title: 'Upcoming Appointment',
          body: 'Reminder: Your ${widget.service['title']} service begins in 2 hours!',
          scheduledTime: reminderTime,
        );
      }
      
      if(mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('SUCCESS'),
            content: const Text('PAYMENT COMPLETED & BOOKING CONFIRMED.'),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: BrutalistTheme.primary, width: 2)),
            actions: [
              BrutalistButton(
                text: 'RETURN HOME',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              )
            ],
          )
        );
      }
    } on StripeException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Cancelled: ${e.error.localizedMessage}')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<BookingProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('CONFIRM', style: Theme.of(context).textTheme.headlineLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrutalistCard(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('SERVICE SUMMARY', style: Theme.of(context).textTheme.labelLarge),
                   const SizedBox(height: 16),
                   Text(widget.service['title'].toString().toUpperCase(), style: Theme.of(context).textTheme.headlineLarge),
                   const SizedBox(height: 8),
                   Text('\$${widget.service['price']}', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                 ],
               ),
            ),
            const SizedBox(height: 32),
            
            Text('SCHEDULE', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            
            OutlinedButton(
              onPressed: _pickDate,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(24),
                side: const BorderSide(color: BrutalistTheme.primary, width: BrutalistTheme.borderWidth),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null 
                      ? 'SELECT DATE' 
                      : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20),
                  ),
                  const Icon(Icons.calendar_today, color: BrutalistTheme.primary),
                ],
              ),
            ),
            
            const Spacer(),
            BrutalistButton(
              text: 'CONFIRM & BOOK',
              isLoading: isLoading,
              onPressed: _confirmBooking,
            ),
          ],
        ),
      ),
    );
  }
}
