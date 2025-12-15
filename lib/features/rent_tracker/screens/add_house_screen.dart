import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:exif/exif.dart';

import '../models/house_entry.dart';
import '../providers/house_provider.dart';

class AddHouseScreen extends StatefulWidget {
  const AddHouseScreen({super.key});

  @override
  State<AddHouseScreen> createState() => _AddHouseScreenState();
}

class _AddHouseScreenState extends State<AddHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  final _addressController = TextEditingController();
  final _rentController = TextEditingController();
  final _serviceChargeController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, bool> _services = {
    'Gas': false,
    'Water': false,
    'Lift': false,
    'Generator': false,
    'Parking': false,
  };

  bool _loadingLocation = false;
  double? _latitude;
  double? _longitude;

  double _rationalToDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    try {
      final dyn = v as dynamic;
      final num? numer = dyn.numerator;
      final num? denom = dyn.denominator;
      if (numer != null && denom != null) {
        final dn = denom.toDouble();
        if (dn == 0) return 0.0;
        return numer.toDouble() / dn;
      }
    } catch (_) {}
    final s = v.toString().trim();
    if (s.isEmpty) return 0.0;
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0].trim());
        final b = double.tryParse(parts[1].trim());
        if (a != null && b != null && b != 0) return a / b;
      }
      final nums = parts.map((p) => double.tryParse(p.trim())).where((e) => e != null).toList();
      if (nums.isNotEmpty) return nums.first!;
    }
    final tokens = s.split(RegExp(r'\s+'));
    if (tokens.length >= 3) {
      final deg = double.tryParse(tokens[0]);
      double min = 0.0;
      double sec = 0.0;
      try {
        if (tokens[1].contains('/')) {
          final p = tokens[1].split('/');
          final a = double.tryParse(p[0].trim());
          final b = double.tryParse(p[1].trim());
          if (a != null && b != null && b != 0) min = a / b;
        } else {
          min = double.tryParse(tokens[1]) ?? 0.0;
        }
      } catch (_) {}
      try {
        if (tokens[2].contains('/')) {
          final p = tokens[2].split('/');
          final a = double.tryParse(p[0].trim());
          final b = double.tryParse(p[1].trim());
          if (a != null && b != null && b != 0) sec = a / b;
        } else {
          sec = double.tryParse(tokens[2]) ?? 0.0;
        }
      } catch (_) {}
      if (deg != null) return deg + (min / 60.0) + (sec / 3600.0);
    }
    return double.tryParse(s) ?? 0.0;
  }

  double _convertToDegreeFromValues(dynamic rawValues) {
    if (rawValues == null) return 0.0;
    List<dynamic> values = [];
    if (rawValues is Iterable) {
      values = rawValues.cast<dynamic>().toList();
    } else {
      final s = rawValues.toString().trim();
      if (s.contains(',')) {
        values = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else {
        values = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      }
    }
    if (values.isEmpty) return 0.0;
    double toDouble(dynamic v) {
      try {
        return _rationalToDouble(v);
      } catch (_) {
        return 0.0;
      }
    }
    final d = toDouble(values[0]);
    final m = values.length > 1 ? toDouble(values[1]) : 0.0;
    final s = values.length > 2 ? toDouble(values[2]) : 0.0;
    final result = d + (m / 60.0) + (s / 3600.0);
    if (result == 0.0) {
      final printable = rawValues.toString();
      final tokens = RegExp(r"(\d+/\d+|\d+\.\d+|\d+)").allMatches(printable).map((m) => m.group(0)).whereType<String>().toList();
      if (tokens.isNotEmpty) {
        double td() {
          final a = tokens.length > 0 ? _rationalToDouble(tokens[0]) : 0.0;
          final b = tokens.length > 1 ? _rationalToDouble(tokens[1]) : 0.0;
          final c = tokens.length > 2 ? _rationalToDouble(tokens[2]) : 0.0;
          return a + (b / 60.0) + (c / 3600.0);
        }
        final alt = td();
        if (alt != 0.0) return alt;
      }
    }
    return result;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source, maxWidth: 1600);
    if (picked != null) {
      final file = File(picked.path);
      setState(() => _imageFile = file);

      try {
        final bytes = await file.readAsBytes();
        final exifData = await readExifFromBytes(bytes);
        if (exifData != null) {
          String? latKey;
          String? lonKey;
          String? latRefKey;
          String? lonRefKey;
          String _normKey(Object? k) => k?.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ?? '';

          for (final k in exifData.keys) {
            final nk = _normKey(k);
            if (latKey == null && (nk.contains('gpslatitude') || nk.contains('gpslat'))) latKey = k?.toString();
            if (lonKey == null && (nk.contains('gpslongitude') || nk.contains('gpslon') || nk.contains('gpslong'))) lonKey = k?.toString();
            if (latRefKey == null && nk.contains('gpslatituderef')) latRefKey = k?.toString();
            if (lonRefKey == null && nk.contains('gpslongituderef')) lonRefKey = k?.toString();
            if (latKey == null && nk == 'latitude') latKey = k?.toString();
            if (lonKey == null && nk == 'longitude') lonKey = k?.toString();
            if (latRefKey == null && nk == 'latituderef') latRefKey = k?.toString();
            if (lonRefKey == null && nk == 'longituderef') lonRefKey = k?.toString();
          }

          double lat = 0.0;
          double lon = 0.0;
          String latRef = '';
          String lonRef = '';

          dynamic _extractTagValue(String? key) {
            if (key == null) return null;
            final tag = exifData[key];
            if (tag == null) return null;
            if (tag.values != null && (tag.values is Iterable) && (tag.values as Iterable).isNotEmpty) return tag.values;
            return tag.printable;
          }

          final rawLat = _extractTagValue(latKey);
          final rawLon = _extractTagValue(lonKey);
          final rawLatRef = _extractTagValue(latRefKey);
          final rawLonRef = _extractTagValue(lonRefKey);

          if (kDebugMode) {
            try {
              print('--- EXIF full dump start ---');
              for (final entry in exifData.entries) {
                final key = entry.key?.toString() ?? '<null>';
                final tag = entry.value;
                final printable = (tag.printable != null) ? tag.printable : '<no-printable>';
                final values = (tag.values != null && (tag.values as Iterable).isNotEmpty) ? tag.values : '<no-values>';
                print('EXIF: $key => printable: $printable | values: $values');
              }
              print('--- EXIF full dump end ---');
              print('rawLat: $rawLat rawLon: $rawLon rawLatRef: $rawLatRef rawLonRef: $rawLonRef');
            } catch (_) {}
          }

          bool imageHasGps = false;
          if (rawLat != null && rawLon != null) {
            imageHasGps = true;
            try {
              lat = _convertToDegreeFromValues(rawLat);
              lon = _convertToDegreeFromValues(rawLon);
            } catch (e) {
              lat = 0.0;
              lon = 0.0;
            }

            if ((lat == 0.0 && lon == 0.0)) {
              try {
                final sLat = rawLat.toString();
                final sLon = rawLon.toString();
                final mLat = RegExp(r'(-?\d+\.\d+)').firstMatch(sLat)?.group(0) ?? RegExp(r'(-?\d+)').firstMatch(sLat)?.group(0);
                final mLon = RegExp(r'(-?\d+\.\d+)').firstMatch(sLon)?.group(0) ?? RegExp(r'(-?\d+)').firstMatch(sLon)?.group(0);
                if (mLat != null && mLon != null) {
                  lat = double.tryParse(mLat) ?? 0.0;
                  lon = double.tryParse(mLon) ?? 0.0;
                }
              } catch (_) {}
            }

            latRef = rawLatRef?.toString() ?? '';
            lonRef = rawLonRef?.toString() ?? '';
          }

          if (imageHasGps) {
            if ((lat != 0.0 || lon != 0.0)) {
              final latSigned = latRef.toUpperCase().contains('S') ? -lat : lat;
              final lonSigned = lonRef.toUpperCase().contains('W') ? -lon : lon;

              if (kDebugMode) print('Parsed image GPS -> lat: $latSigned lon: $lonSigned');

              setState(() {
                _latitude = double.parse(latSigned.toStringAsFixed(6));
                _longitude = double.parse(lonSigned.toStringAsFixed(6));
              });
              _showSnack('Location extracted from image metadata');
              return;
            } else {
              _showSnack('Image contains GPS metadata but it could not be parsed. Using device location if available.');
              if (_latitude == null || _longitude == null) await _fetchLocation();
              return;
            }
          } else {
            if (_latitude == null || _longitude == null) {
              await _fetchLocation();
            }
          }
        } else {
          if (_latitude == null || _longitude == null) {
            await _fetchLocation();
          }
        }
      } catch (e) {
        if (_latitude == null || _longitude == null) {
          await _fetchLocation();
        }
      }
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _loadingLocation = true);
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied. Please enable from settings.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .timeout(const Duration(seconds: 8), onTimeout: () {
        throw TimeoutException('Location request timed out');
      });

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } on TimeoutException catch (_) {
      _showSnack('Location request timed out. Please try again.');
    } on Exception catch (e) {
      _showSnack('Unable to get location: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _rentController.dispose();
    _serviceChargeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_imageFile == null) {
      _showSnack('Please select an image.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<HouseProvider>(context, listen: false);
    final id = provider.generateId();

    final entry = HouseEntry(
      id: id,
      imagePath: _imageFile!.path,
      address: _addressController.text.trim(),
      rent: double.parse(_rentController.text.trim()),
      serviceCharge: _serviceChargeController.text.trim().isEmpty ? null : double.parse(_serviceChargeController.text.trim()),
      services: _services.entries.where((e) => e.value).map((e) => e.key).toList(),
      notes: _notesController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      createdAt: DateTime.now(),
    );

    await provider.addHouse(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final cardColor = theme.cardColor;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surface.withAlpha(224), // ~0.88 opacity
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('Add House', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Card(
                color: surface,
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              builder: (_) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Camera'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _pickImage(ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Gallery'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _pickImage(ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: _imageFile == null
                                    ? LinearGradient(colors: [cardColor.withAlpha(5), cardColor.withAlpha(15)])
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withAlpha(_imageFile == null ? 15 : 56),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(color: primary.withAlpha(36)),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: _imageFile == null
                                  ? Container(
                                      color: Colors.transparent,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.camera_alt, size: 36, color: onSurface.withAlpha(153)),
                                            const SizedBox(height: 8),
                                            Text('Add photo', style: theme.textTheme.bodySmall?.copyWith(color: onSurface.withAlpha(179))),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      _imageFile!,
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            filled: true,
                            fillColor: cardColor.withAlpha(5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 1.4)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _rentController,
                                decoration: InputDecoration(
                                  labelText: 'Asked Rent',
                                  filled: true,
                                  fillColor: cardColor.withAlpha(5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 1.4)),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Rent is required';
                                  final n = double.tryParse(v);
                                  if (n == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _serviceChargeController,
                                decoration: InputDecoration(
                                  labelText: 'Service Charge (optional)',
                                  filled: true,
                                  fillColor: cardColor.withAlpha(5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 1.4)),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Optional Services', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        ..._services.keys.map((k) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CheckboxListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: cardColor.withAlpha(5),
                              title: Text(k, style: theme.textTheme.bodyMedium),
                              value: _services[k],
                              onChanged: (v) => setState(() => _services[k] = v ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes',
                            filled: true,
                            fillColor: cardColor.withAlpha(5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 1.4)),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Latitude',
                                  filled: true,
                                  fillColor: cardColor.withAlpha(5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                readOnly: true,
                                controller: TextEditingController(text: _latitude?.toStringAsFixed(6) ?? ''),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Longitude',
                                  filled: true,
                                  fillColor: cardColor.withAlpha(5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                readOnly: true,
                                controller: TextEditingController(text: _longitude?.toStringAsFixed(6) ?? ''),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _loadingLocation
                                ? SizedBox(width: 44, height: 44, child: Center(child: CircularProgressIndicator(color: primary)))
                                : Container(
                                    decoration: BoxDecoration(
                                      color: cardColor.withAlpha(5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: _fetchLocation,
                                      icon: Icon(Icons.my_location, color: primary),
                                    ),
                                  ),
                          ],
                        ),
                        if (_latitude == null || _longitude == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Location not available — you can still save and add location later.',
                                style: theme.textTheme.bodySmall?.copyWith(color: onSurface.withAlpha(166))),
                          ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              elevation: 8,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

