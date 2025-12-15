import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File) onImagePicked;
  const ImagePickerWidget({super.key, required this.onImagePicked});

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _file;

  Future<void> _pick(ImageSource src) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: src);
    if (picked != null) {
      final f = File(picked.path);
      setState(() => _file = f);
      widget.onImagePicked(f);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  _pick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pick(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
      child: _file == null
          ? Container(width: 140, height: 140, color: Colors.grey[200], child: const Icon(Icons.camera_alt, size: 48, color: Colors.grey))
          : Image.file(_file!, width: 140, height: 140, fit: BoxFit.cover),
    );
  }
}

