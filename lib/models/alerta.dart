import 'tipo_sanguineo.dart';

enum TipoAlerta {
  urgencia('Urgência'),
  campanha('Estoque crítico');

  const TipoAlerta(this.label);
  final String label;
}

/// Alerta/campanha publicado por um hemocentro ou hospital (RF06).
class Alerta {
  Alerta({
    required this.id,
    required this.instituicaoId,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.tiposNecessarios,
    required this.criadoEm,
    this.ativo = true,
    this.notificados = 0,
  });

  final String id;
  final String instituicaoId;
  final TipoAlerta tipo;
  final String titulo;
  final String mensagem;

  /// Tipos sanguíneos de DOADOR que devem ser avisados.
  final Set<TipoSanguineo> tiposNecessarios;
  final DateTime criadoEm;
  bool ativo;

  /// Quantos doadores receberam a notificação no momento da publicação.
  final int notificados;

  Map<String, dynamic> toJson() => {
        'id': id,
        'instituicaoId': instituicaoId,
        'tipo': tipo.name,
        'titulo': titulo,
        'mensagem': mensagem,
        'tiposNecessarios': tiposNecessarios.map((t) => t.name).toList(),
        'criadoEm': criadoEm.toIso8601String(),
        'ativo': ativo,
        'notificados': notificados,
      };

  factory Alerta.fromJson(Map<String, dynamic> j) => Alerta(
        id: j['id'] as String,
        instituicaoId: j['instituicaoId'] as String,
        tipo: TipoAlerta.values.byName(j['tipo'] as String),
        titulo: j['titulo'] as String,
        mensagem: j['mensagem'] as String,
        tiposNecessarios: (j['tiposNecessarios'] as List)
            .map((e) => TipoSanguineo.values.byName(e as String))
            .toSet(),
        criadoEm: DateTime.parse(j['criadoEm'] as String),
        ativo: j['ativo'] as bool? ?? true,
        notificados: (j['notificados'] as num?)?.toInt() ?? 0,
      );
}
