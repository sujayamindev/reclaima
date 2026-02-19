# Smart Receipt & Warranty Manager - Mobile App

Flutter mobile application for managing receipts with OCR and warranty tracking.

## Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Android/iOS device or emulator

## Setup Instructions

### 1. Install Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Firebase Configuration

#### Android
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`

#### iOS
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`

### 3. Generate Code

Run the code generator for models and database:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure API Endpoint

Edit `lib/core/constants/app_constants.dart`:

- For **Android Emulator**: Use `http://10.0.2.2:8000/api/v1`
- For **iOS Simulator**: Use `http://localhost:8000/api/v1`
- For **Physical Device**: Use your computer's IP address

### 5. Run the App

```bash
flutter run
```

## Project Structure

```
mobile/
├── lib/
│   ├── core/
│   │   ├── constants/      # App constants and configuration
│   │   └── utils/          # Utility functions
│   ├── data/
│   │   ├── models/         # Data models
│   │   └── database/       # Drift database
│   ├── services/           # API and business logic
│   ├── providers/          # Riverpod state management
│   ├── screens/            # UI screens
│   │   ├── auth/
│   │   ├── home/
│   │   └── receipt/
│   ├── widgets/            # Reusable widgets
│   └── main.dart
└── pubspec.yaml
```

## Key Features

- ✅ Firebase Authentication (Email/Password)
- ✅ Offline-first architecture with Drift
- ✅ Receipt OCR processing
- ✅ Warranty tracking with expiry notifications
- ✅ Image upload and compression
- ✅ Material Design 3 UI

## State Management

Using **Riverpod** for:
- Authentication state
- Receipt management
- API calls
- Database operations

## Local Database

Using **Drift** (SQLite) for:
- Offline receipt storage
- Upload queue management
- Sync state tracking

## API Communication

Using **Dio** for:
- HTTP requests
- File uploads
- Authentication interceptors
- Error handling

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

## Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Build Issues

1. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Check Flutter version**:
   ```bash
   flutter --version
   ```

3. **Check for issues**:
   ```bash
   flutter doctor
   ```

### Common Errors

- **Firebase not initialized**: Ensure `google-services.json` / `GoogleService-Info.plist` are in the correct locations
- **API connection failed**: Check API endpoint in `app_constants.dart`
- **Code generation errors**: Run `flutter pub run build_runner clean` then rebuild

## Development

### Hot Reload
While running the app, press `r` in the terminal for hot reload.

### Hot Restart
Press `R` for hot restart (clears state).

### Debug Mode
The app includes:
- Logger for debugging
- Pretty printer for logs
- Error stack traces

## Dependencies

Key packages:
- `flutter_riverpod`: State management
- `drift`: Local database
- `firebase_auth`: Authentication
- `firebase_messaging`: Push notifications
- `dio`: HTTP client
- `image_picker`: Image selection
- `flutter_image_compress`: Image optimization
- `json_annotation`: JSON serialization

## Next Steps

1. Add Firebase configuration files
2. Configure backend API URL
3. Implement push notifications
4. Add warranty expiry alerts
5. Implement background sync
6. Add biometric authentication
7. Implement search functionality
8. Add export to PDF feature
