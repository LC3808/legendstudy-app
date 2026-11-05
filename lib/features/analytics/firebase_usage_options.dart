import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public app identifiers from the release pipeline, never invented defaults.
FirebaseOptions usageFirebaseOptions() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if (apiKey.isEmpty || appId.isEmpty || sender.isEmpty || project.isEmpty) {
    throw StateError('Firebase application configuration is incomplete');
  }
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: sender,
    projectId: project,
    iosBundleId: defaultTargetPlatform == TargetPlatform.iOS
        ? 'com.legendstudy.app'
        : null,
  );
}
