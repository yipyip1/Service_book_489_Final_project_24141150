import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_button.dart';
import '../../core/widgets/brutalist_card.dart';
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
    try {
      await provider.createBooking(
        widget.service['_id'], 
        _selectedDate!, 
        (widget.service['price'] as num).toDouble(),
      );
      
      if(mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('SUCCESS'),
            content: const Text('YOUR BOOKING IS CONFIRMED.'),
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
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
