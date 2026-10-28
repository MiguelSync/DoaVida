// Ajusta os arquivos nativos gerados pelo `flutter create`:
// - Android: permissões (internet, localização, notificações) e
//   core library desugaring (exigido pelo flutter_local_notifications);
// - iOS: texto de permissão de localização.
//
// Uso (na raiz do projeto): dart tool/configurar_plataformas.dart
import 'dart:io';

void main() {
  _android();
  _ios();
  stdout.writeln('\n✔ Configuração nativa concluída.');
}

void _android() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('⚠ AndroidManifest.xml não encontrado. Rode o flutter create antes.');
    return;
  }
  var xml = manifest.readAsStringSync();
  const permissoes = [
    'android.permission.INTERNET',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.POST_NOTIFICATIONS',
  ];
  final faltando = permissoes
      .where((p) => !xml.contains('"$p"'))
      .map((p) => '    <uses-permission android:name="$p"/>')
      .join('\n');
  if (faltando.isNotEmpty) {
    xml = xml.replaceFirst('<application', '$faltando\n    <application');
    manifest.writeAsStringSync(xml);
    stdout.writeln('• Permissões adicionadas ao AndroidManifest.xml');
  } else {
    stdout.writeln('• AndroidManifest.xml já estava configurado');
  }

  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) {
    var g = kts.readAsStringSync();
    if (g.contains('isCoreLibraryDesugaringEnabled')) {
      stdout.writeln('• build.gradle.kts já estava configurado');
      return;
    }
    if (g.contains('compileOptions {')) {
      g = g.replaceFirst('compileOptions {',
          'compileOptions {\n        isCoreLibraryDesugaringEnabled = true');
    } else {
      g += '\nandroid {\n    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n    }\n}\n';
    }
    g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n';
    kts.writeAsStringSync(g);
    stdout.writeln('• Desugaring habilitado em android/app/build.gradle.kts');
  } else if (groovy.existsSync()) {
    var g = groovy.readAsStringSync();
    if (g.contains('coreLibraryDesugaringEnabled')) {
      stdout.writeln('• build.gradle já estava configurado');
      return;
    }
    if (g.contains('compileOptions {')) {
      g = g.replaceFirst('compileOptions {',
          'compileOptions {\n        coreLibraryDesugaringEnabled true');
    } else {
      g += '\nandroid {\n    compileOptions {\n        coreLibraryDesugaringEnabled true\n    }\n}\n';
    }
    g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n";
    groovy.writeAsStringSync(g);
    stdout.writeln('• Desugaring habilitado em android/app/build.gradle');
  } else {
    stderr.writeln('⚠ build.gradle do app Android não encontrado.');
  }
}

void _ios() {
  final plist = File('ios/Runner/Info.plist');
  if (!plist.existsSync()) {
    stdout.writeln('• iOS não gerado (ignorando)');
    return;
  }
  var xml = plist.readAsStringSync();
  if (xml.contains('NSLocationWhenInUseUsageDescription')) {
    stdout.writeln('• Info.plist já estava configurado');
    _iosNotificacoesEmPrimeiroPlano();
    return;
  }
  final i = xml.lastIndexOf('</dict>');
  if (i < 0) return;
  const chave = '\t<key>NSLocationWhenInUseUsageDescription</key>\n'
      '\t<string>Usamos sua localização para mostrar os hemocentros e hospitais mais próximos de você.</string>\n';
  xml = xml.substring(0, i) + chave + xml.substring(i);
  plist.writeAsStringSync(xml);
  stdout.writeln('• Permissão de localização adicionada ao Info.plist');

  _iosNotificacoesEmPrimeiroPlano();
}

/// Faz as notificações aparecerem também com o app aberto no iOS
/// (recomendação do plugin flutter_local_notifications).
void _iosNotificacoesEmPrimeiroPlano() {
  final arquivo = File('ios/Runner/AppDelegate.swift');
  if (!arquivo.existsSync()) return;
  var swift = arquivo.readAsStringSync();
  if (swift.contains('UNUserNotificationCenter')) return;
  const registro = 'GeneratedPluginRegistrant.register(';
  final i = swift.indexOf(registro);
  if (i < 0 || !swift.contains('import Flutter')) {
    stdout.writeln('• AppDelegate.swift com formato diferente — ajuste de notificação ignorado');
    return;
  }
  final inicioLinha = swift.lastIndexOf('\n', i) + 1;
  final indentacao = swift.substring(inicioLinha, i);
  swift = swift.substring(0, inicioLinha) +
      '${indentacao}UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate\n' +
      swift.substring(inicioLinha);
  swift = swift.replaceFirst('import Flutter', 'import Flutter\nimport UserNotifications');
  arquivo.writeAsStringSync(swift);
  stdout.writeln('• AppDelegate.swift ajustado para notificações em primeiro plano');
}
