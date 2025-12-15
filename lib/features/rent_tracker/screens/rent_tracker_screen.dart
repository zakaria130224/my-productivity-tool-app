import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/house_provider.dart';
import '../widgets/house_card.dart';
import 'add_house_screen.dart';
import 'detail_screen.dart';

class RentTrackerScreen extends StatelessWidget {
  const RentTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Rent Tracker'), 
      ),
      body: Consumer<HouseProvider>(
        builder: (context, provider, _) {
          final houses = provider.houses;
          final totalRent = houses.fold(0.0, (sum, item) => sum + item.rent);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circle Stat Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          _buildStatusBadge(colorScheme.secondary, '2 Active'),
                          const SizedBox(width: 8),
                          _buildStatusBadge(Colors.grey, '1 Vacant'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Circle Graph
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${houses.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Houses',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // List items next to circle
                      Expanded(
                        child: Column(
                          children: [
                            _buildInfoRow(context, Icons.map_outlined, 'Map View'),
                            _buildInfoRow(context, Icons.history, 'History'),
                            _buildInfoRow(context, Icons.security, 'Security'),
                          ],
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Browse Products / Houses Grid
                  Text(
                    'Your Houses',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (houses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('No houses added yet.', style: TextStyle(color: Colors.grey[400])),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7, // Adjust for card height
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: houses.length,
                      itemBuilder: (context, index) {
                        return HouseCard(
                          entry: houses[index],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DetailScreen(id: houses[index].id)),
                          ),
                        );
                      },
                    ),
                    
                  // Extra padding for FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddHouseScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusBadge(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
