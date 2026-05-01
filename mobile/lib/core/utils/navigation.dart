// coverage:ignore-file
import 'package:flutter/material.dart';

/// Global navigator key used to push routes from outside the widget tree
/// (e.g. when handling FCM notification taps in the background).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
