import 'dart:io';
import 'dart:convert';

class HouseEntry {
  final String id;
  final String imagePath; // store path for persistence
  final String address;
  final double rent;
  final double? serviceCharge;
  final List<String> services;
  final String notes;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  HouseEntry({
    required this.id,
    required this.imagePath,
    required this.address,
    required this.rent,
    this.serviceCharge,
    required this.services,
    required this.notes,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  File get image => File(imagePath);

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'address': address,
        'rent': rent,
        'serviceCharge': serviceCharge,
        'services': services,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HouseEntry.fromJson(Map<String, dynamic> json) => HouseEntry(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        address: json['address'] as String,
        rent: (json['rent'] as num).toDouble(),
        serviceCharge: json['serviceCharge'] != null ? (json['serviceCharge'] as num).toDouble() : null,
        services: (json['services'] as List<dynamic>).map((e) => e as String).toList(),
        notes: json['notes'] as String,
        latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
        longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static List<HouseEntry> listFromJson(String jsonString) {
    final List data = jsonDecode(jsonString) as List;
    return data.map((e) => HouseEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<HouseEntry> houses) {
    final data = houses.map((h) => h.toJson()).toList();
    return jsonEncode(data);
  }
}
