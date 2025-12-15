House Rent App

An offline-only Flutter app to quickly save house rent information with photos, notes, and GPS location.

Run

```bash
flutter pub get
flutter run
```

Notes
- This app stores data in-memory only (ChangeNotifier + Provider). Closing the app will lose data.
- Permissions: add the following to AndroidManifest and Info.plist for location and camera/gallery access.

Android (android/app/src/main/AndroidManifest.xml):
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- CAMERA
- READ/WRITE external storage (if targeting older SDKs)

iOS (ios/Runner/Info.plist):
- NSLocationWhenInUseUsageDescription
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription

Packages used
- provider
- image_picker
- geolocator
- uuid
- url_launcher

Project structure (lib/)
- main.dart
- models/house_entry.dart
- providers/house_provider.dart
- screens/home_screen.dart
- screens/add_house_screen.dart
- screens/detail_screen.dart
- widgets/house_card.dart
- widgets/image_picker_widget.dart

Limitations
- No persistence (by design)
- Minimal UI and error handling for brevity

