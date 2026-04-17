import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/brutalist_theme.dart';
import '../../core/widgets/brutalist_card.dart';
import 'services_provider.dart';
import 'service_details_screen.dart';
import 'add_service_screen.dart';

class BrowseServicesScreen extends StatefulWidget {
  const BrowseServicesScreen({super.key});

  @override
  State<BrowseServicesScreen> createState() => _BrowseServicesScreenState();
}

class _BrowseServicesScreenState extends State<BrowseServicesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch services on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('SERVICES', style: Theme.of(context).textTheme.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 32),
            onPressed: () {
              final searchCtrl = TextEditingController();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('SEARCH CATEGORY'),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, 
                    side: BorderSide(color: BrutalistTheme.primary, width: 2)
                  ),
                  content: TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Cleaning',
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('SEARCH', style: TextStyle(color: BrutalistTheme.primary, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        context.read<ServiceProvider>().fetchServices(searchCtrl.text);
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: const Text('CLEAR', style: TextStyle(color: BrutalistTheme.primary)),
                      onPressed: () {
                        context.read<ServiceProvider>().fetchServices();
                        Navigator.pop(context);
                      },
                    )
                  ],
                )
              );
            },
          ),
        ],
      ),
      body: provider.isLoading 
          ? const Center(child: CircularProgressIndicator(color: BrutalistTheme.primary))
          : RefreshIndicator(
              color: BrutalistTheme.primary,
              onRefresh: () => provider.fetchServices(),
              child: ListView.separated(
                padding: const EdgeInsets.all(24.0),
                itemCount: provider.services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final service = provider.services[index];
                  return BrutalistCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailsScreen(service: service),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Chip Component
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: BrutalistTheme.primary, width: BrutalistTheme.borderWidth),
                          ),
                          child: Text(
                            service['category'] ?? 'GENERAL',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          service['title'].toString().toUpperCase(),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${service['price']}',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 32, color: BrutalistTheme.primary),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BrutalistTheme.primary,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add, color: BrutalistTheme.surface),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddServiceScreen()));
        },
      ),
    );
  }
}
