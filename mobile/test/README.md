# Mobile Application Testing

This directory contains automated widget and unit tests for the Flutter application.

## 🧪 Running Tests

### Standard Test Run
Run all tests from the `mobile` directory:
```bash
flutter test
```

### With Coverage
To generate a coverage report:
```bash
flutter test --coverage
```
The report will be generated at `mobile/coverage/lcov.info`.

## 🛠️ Test Architecture

The application uses **Riverpod** for state management. To test UI components in isolation from Firebase and the Backend API, we use `ProviderScope` overrides in our tests:

```dart
ProviderScope(
  overrides: [
    userProfileProvider.overrideWith((ref) => mockUser),
    receiptsProvider.overrideWith((ref) => []),
  ],
  child: const MyApp(),
)
```

## 📋 Best Practices
- **Mock External Services:** Never hit the real API or Firebase in a widget test.
- **Pump and Settle:** Always use `tester.pumpAndSettle()` after interactions (taps, text input) to wait for animations to complete.
- **Small, Focused Tests:** Prefer many small tests over one giant end-to-end flow.
