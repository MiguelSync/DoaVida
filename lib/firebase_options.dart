// Configuração do projeto Firebase "DoaVida" (doavida-b5ef1).
// Mesmo formato gerado pelo `flutterfire configure`.
//
// Estes valores identificam o projeto e NÃO são senhas: quem protege os
// dados são as regras do Firestore (firestore.rules) e o Firebase Auth.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS || TargetPlatform.macOS => ios,
      _ => web,
    };
  }

  static const _apiKey = 'AIzaSyA4XO6TisjpanfqWPT-jbSJD-Yb6XLzUOo';
  static const _projectId = 'doavida-b5ef1';
  static const _senderId = '71385485787';
  static const _bucket = 'doavida-b5ef1.firebasestorage.app';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:71385485787:web:6bf86eff474a9291f717fe',
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: 'doavida-b5ef1.firebaseapp.com',
    storageBucket: _bucket,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:71385485787:android:fef48c0357f96ae5f717fe',
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:71385485787:ios:6cf3a607c4f44008f717fe',
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
    iosBundleId: 'br.edu.unidavi.doaSangue',
  );
}
