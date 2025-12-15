import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../models/house_entry.dart';

class HouseProvider extends ChangeNotifier {
  static const _legacyStorageKey = 'houses_v1';
  final List<HouseEntry> _houses = [];
  final Uuid _uuid = const Uuid();

  HouseProvider() {
    _loadFromStorage();
  }

  List<HouseEntry> get houses => List.unmodifiable(_houses);

  String generateId() => _uuid.v4();

  HouseEntry? getById(String id) {
    try {
      return _houses.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Directory> get _appDir async {
    return await getApplicationDocumentsDirectory();
  }

  Future<File> get _storageFile async {
    final dir = await _appDir;
    return File('${dir.path}/houses.json');
  }

  Future<void> _loadFromStorage() async {
    try {
      final file = await _storageFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.trim().isNotEmpty) {
          final loaded = HouseEntry.listFromJson(jsonString);
          _houses
            ..clear()
            ..addAll(loaded);
          notifyListeners();
          return;
        }
      }

      // If no file found, try legacy SharedPreferences migration
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_legacyStorageKey);
      if (legacy != null && legacy.trim().isNotEmpty) {
        try {
          final loaded = HouseEntry.listFromJson(legacy);
          _houses
            ..clear()
            ..addAll(loaded);
          // persist to file
          await _saveToStorage();
          // remove legacy key
          await prefs.remove(_legacyStorageKey);
          notifyListeners();
          return;
        } catch (_) {
          // ignore malformed legacy data
        }
      }
    } catch (_) {
      // ignore read errors
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final file = await _storageFile;
      final jsonString = HouseEntry.listToJson(_houses);
      await file.writeAsString(jsonString, flush: true);
    } catch (_) {
      // ignore write errors
    }
  }

  /// Add a house entry. If [imagePath] points to a temporary file (e.g., from the image picker),
  /// this copies the image into the app documents directory and stores the new path.
  Future<void> addHouse(HouseEntry entry, {bool copyImageToAppDir = true}) async {
    var finalEntry = entry;

    if (copyImageToAppDir) {
      try {
        final src = File(entry.imagePath);
        if (await src.exists()) {
          final dir = await _appDir;
          final filename = '${entry.id}_${DateTime.now().millisecondsSinceEpoch}${extension(entry.imagePath)}';
          final dest = File('${dir.path}/$filename');
          await src.copy(dest.path);
          finalEntry = HouseEntry(
            id: entry.id,
            imagePath: dest.path,
            address: entry.address,
            rent: entry.rent,
            serviceCharge: entry.serviceCharge,
            services: entry.services,
            notes: entry.notes,
            latitude: entry.latitude,
            longitude: entry.longitude,
            createdAt: entry.createdAt,
          );
        }
      } catch (_) {
        // ignore copy failures and keep original path
      }
    }

    _houses.insert(0, finalEntry);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> updateHouse(HouseEntry updated) async {
    final idx = _houses.indexWhere((h) => h.id == updated.id);
    if (idx == -1) return;
    _houses[idx] = updated;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> removeById(String id) async {
    final idx = _houses.indexWhere((h) => h.id == id);
    if (idx == -1) return;
    final entry = _houses[idx];
    // try delete image file
    try {
      final f = File(entry.imagePath);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // ignore
    }
    _houses.removeAt(idx);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> clearAll() async {
    // delete stored images
    for (final h in _houses) {
      try {
        final f = File(h.imagePath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _houses.clear();
    final file = await _storageFile;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
    notifyListeners();
  }
}

// small helper because dart:io's basename/extension requires package:path but we avoid new dep
String extension(String path) {
  final idx = path.lastIndexOf('.');
  if (idx == -1) return '';
  return path.substring(idx);
}
