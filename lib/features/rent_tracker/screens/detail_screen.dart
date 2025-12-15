import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../providers/house_provider.dart';

class DetailScreen extends StatelessWidget {
  final String id;
  const DetailScreen({super.key, required this.id});

  Future<void> _openInMaps(BuildContext context, double lat, double lon, String address) async {
    final label = address.isNotEmpty ? address : '$lat,$lon';
    final candidates = <Uri>[
      // geo:lat,long?q=lat,long (android) forces a pin at coordinates
      Uri.parse('geo:$lat,$lon?q=$lat,$lon'), 
      // google maps universal link
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon'),
      // apple maps
      Uri.parse('https://maps.apple.com/?ll=$lat,$lon&q=House%20Location'),
    ];

    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<HouseProvider>(context);
    final entry = provider.getById(id);

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details')),
        body: const Center(child: Text('Item not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(entry.image.path),
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                entry.address,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rent Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monthly Rent', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                            Text(
                              '\$${entry.rent.toStringAsFixed(0)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (entry.serviceCharge != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Service', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                              Text(
                                '+\$${entry.serviceCharge!.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Services
                  if (entry.services.isNotEmpty) ...[
                    Text('Included Services', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: entry.services.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                          ),
                          child: Text(s, style: TextStyle(color: colorScheme.primary)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notes
                  if (entry.notes.isNotEmpty) ...[
                    Text('Notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(entry.notes, style: theme.textTheme.bodyMedium),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Location
                  Text('Location', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (entry.latitude != null && entry.longitude != null)
                        ? FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(entry.latitude!, entry.longitude!),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.house_rent_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(entry.latitude!, entry.longitude!),
                                    width: 80,
                                    height: 80,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const Center(child: Text('Location not available')),
                  ),
                  const SizedBox(height: 8),
                  if (entry.latitude != null && entry.longitude != null)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _openInMaps(context, entry.latitude!, entry.longitude!, entry.address),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in External Maps'),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
