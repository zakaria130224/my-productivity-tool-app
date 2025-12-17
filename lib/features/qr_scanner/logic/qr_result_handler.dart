import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../notes/screens/notes_screen.dart';

class QrResultHandler {
  static Future<void> handleResult(BuildContext context, String? data) async {
    if (data == null || data.isEmpty) return;

    // Determine Action details
    String actionTitle = 'Unknown Action';
    String actionDescription = 'Perform action with scanned data?';
    String contentPreview = data;
    Future<void> Function() onConfirm;

    if (_isUrl(data)) {
      actionTitle = 'Open Website';
      actionDescription = 'Open this link in your browser?';
      onConfirm = () async {
        final uri = Uri.parse(data.startsWith('http') ? data : 'https://$data');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      };
    } else if (data.startsWith('WIFI:')) {
      actionTitle = 'Connect to WiFi';
      final ssid = _extractWifiSsid(data);
      actionDescription = 'Connect to network "$ssid"?';
      contentPreview = 'Network: $ssid\nFull Data: $data';
      onConfirm = () => _handleWifi(context, data);
    } else if (data.contains('BEGIN:VCARD') || data.startsWith('MECARD:')) {
      actionTitle = 'Add Contact';
      final name = _extractContactName(data);
      actionDescription = 'Add "$name" to your contacts?';
      onConfirm = () => _handleContact(context, data);
    } else {
      actionTitle = 'Save Note';
      actionDescription = 'Save this text to your notes?';
      onConfirm = () async => _addToNotes(context, data);
    }

    // Show Confirmation Dialog
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(actionDescription),
            const SizedBox(height: 12),
            const Text('Preview:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                contentPreview,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await onConfirm();
    }
  }

  static bool _isUrl(String data) {
    return data.startsWith('http://') ||
        data.startsWith('https://') ||
        data.startsWith('www.');
  }

  // --- Helpers to extract info for preview ---

  static String _extractWifiSsid(String data) {
    // Format: WIFI:S:MySSID;...
    final parts = data.split(';');
    for (final part in parts) {
      if (part.startsWith('S:') || (part.startsWith('WIFI:S:'))) {
        // handle WIFI:S: directly if it wasn't split perfectly or just S:
        // split separates WIFI:S:MySSID -> [WIFI:S:MySSID] if no ; before it
        // standard format WIFI:S:MySSID;
        if (part.startsWith('WIFI:S:')) return part.substring(7);
        return part.substring(2);
      }
    }
    return 'Unknown SSID';
  }

  static String _extractContactName(String data) {
    if (data.contains('FN:')) {
      final match = RegExp(r'FN:(.*?)(\n|$)').firstMatch(data);
      if (match != null) return match.group(1)?.trim() ?? 'Unknown';
    } else if (data.contains('N:')) {
      final match = RegExp(r'N:(.*?)(\n|$)').firstMatch(data);
      if (match != null) return match.group(1)?.trim() ?? 'Unknown';
    }
    return 'Unknown Contact';
  }

  // --- Action Handlers (Dialogs Removed) ---

  static Future<void> _handleWifi(BuildContext context, String data) async {
    String? ssid;
    String? password;
    NetworkSecurity security = NetworkSecurity.NONE;

    final parts = data.split(';');
    for (final part in parts) {
      String p = part.trim();
      if (p.startsWith('S:') || p.startsWith('WIFI:S:')) {
        ssid = p.startsWith('WIFI:S:') ? p.substring(7) : p.substring(2);
      } else if (p.startsWith('P:')) {
        password = p.substring(2);
      } else if (p.startsWith('T:')) {
        final type = p.substring(2);
        if (type == 'WPA' || type == 'WPA2') {
          security = NetworkSecurity.WPA;
        } else if (type == 'WEP') security = NetworkSecurity.WEP;
      }
    }

    if (ssid != null) {
      if (await Permission.location.request().isGranted) {
        bool connected = await WiFiForIoTPlugin.connect(ssid,
            password: password, security: security);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  connected ? 'Connected to $ssid' : 'Failed to connect')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location permission required for WiFi')));
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid WiFi QR Code')));
      }
    }
  }

  static Future<void> _handleContact(BuildContext context, String data) async {
    // Redo parsing to get all objects, or just simplified parsing as before
    String name = _extractContactName(data);
    String? phone;

    if (data.contains('TEL:')) {
      final match = RegExp(r'TEL:(.*?)(\n|$)').firstMatch(data);
      if (match != null) phone = match.group(1)?.trim();
    }

    if (await FlutterContacts.requestPermission()) {
      final newContact = Contact()..name.first = name;
      if (phone != null) {
        newContact.phones = [Phone(phone)];
      }
      try {
        await newContact.insert();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Added $name to contacts')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add contact: $e')));
        }
      }
    }
  }

  static void _addToNotes(BuildContext context, String data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotesScreen(initialNote: data),
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Added to Notes')));
  }
}
