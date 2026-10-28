/// Notificação entregue a um doador (caixa de entrada do app — RF07).
class Notificacao {
  Notificacao({
    required this.id,
    required this.doadorId,
    required this.titulo,
    required this.corpo,
    required this.criadaEm,
    this.alertaId,
    this.lida = false,
  });

  final String id;
  final String doadorId;
  final String? alertaId;
  final String titulo;
  final String corpo;
  final DateTime criadaEm;
  bool lida;

  Map<String, dynamic> toJson() => {
        'id': id,
        'doadorId': doadorId,
        'alertaId': alertaId,
        'titulo': titulo,
        'corpo': corpo,
        'criadaEm': criadaEm.toIso8601String(),
        'lida': lida,
      };

  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
        id: j['id'] as String,
        doadorId: j['doadorId'] as String,
        alertaId: j['alertaId'] as String?,
        titulo: j['titulo'] as String,
        corpo: j['corpo'] as String,
        criadaEm: DateTime.parse(j['criadaEm'] as String),
        lida: j['lida'] as bool? ?? false,
      );
}
