import 'package:intl/intl.dart';

final DateFormat _data = DateFormat('dd/MM/yyyy', 'pt_BR');
final DateFormat _dataCurta = DateFormat('dd/MM', 'pt_BR');
final DateFormat _hora = DateFormat('HH:mm', 'pt_BR');
final DateFormat _extenso = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');

String fData(DateTime d) => _data.format(d);
String fDataCurta(DateTime d) => _dataCurta.format(d);
String fHora(DateTime d) => _hora.format(d);
String fDataHora(DateTime d) => '${_data.format(d)} às ${_hora.format(d)}';

/// "Terça-feira, 4 de novembro"
String fDataExtenso(DateTime d) {
  final s = _extenso.format(d);
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

String fDistancia(double metros) {
  if (metros < 1000) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Remove a parte de horário de uma data.
DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Soma dias de calendário (evita problemas de horário de verão com Duration).
DateTime somarDias(DateTime d, int dias) =>
    DateTime(d.year, d.month, d.day + dias, d.hour, d.minute);

int diasEntre(DateTime de, DateTime ate) =>
    (soData(ate).difference(soData(de)).inHours / 24).round();

/// Tempo relativo simples: "há 2 dias", "há 3 h", "agora".
String fRelativo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays == 1) return 'ontem';
  if (diff.inDays < 30) return 'há ${diff.inDays} dias';
  return fData(d);
}

String primeiroNome(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  return partes.isEmpty ? nome : partes.first;
}

/// "Mariana C." — usado no painel da instituição para expor o mínimo (LGPD).
String nomeReduzido(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  if (partes.length < 2) return nome;
  return '${partes.first} ${partes.last[0]}.';
}

String iniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  if (partes.isEmpty || partes.first.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}

String apenasDigitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

int _sequencia = 0;

/// Identificador único simples para os registros locais.
String gerarId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_sequencia++).toRadixString(36)}';

/// Primeiro elemento que satisfaz [teste], ou null.
T? primeiro<T>(Iterable<T> itens, bool Function(T) teste) {
  for (final item in itens) {
    if (teste(item)) return item;
  }
  return null;
}
