enum StatusAgendamento {
  agendado('Aguardando confirmação'),
  confirmado('Confirmado'),
  realizado('Doação realizada'),
  cancelado('Cancelado'),
  faltou('Não compareceu');

  const StatusAgendamento(this.label);
  final String label;

  bool get ativo =>
      this == StatusAgendamento.agendado ||
      this == StatusAgendamento.confirmado;
}

/// Agendamento de doação em um hemocentro/hospital (RF03).
class Agendamento {
  Agendamento({
    required this.id,
    required this.doadorId,
    required this.instituicaoId,
    required this.dataHora,
    required this.status,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  final String id;
  final String doadorId;
  final String instituicaoId;
  final DateTime dataHora;
  StatusAgendamento status;
  final DateTime criadoEm;

  Map<String, dynamic> toJson() => {
        'id': id,
        'doadorId': doadorId,
        'instituicaoId': instituicaoId,
        'dataHora': dataHora.toIso8601String(),
        'status': status.name,
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory Agendamento.fromJson(Map<String, dynamic> j) => Agendamento(
        id: j['id'] as String,
        doadorId: j['doadorId'] as String,
        instituicaoId: j['instituicaoId'] as String,
        dataHora: DateTime.parse(j['dataHora'] as String),
        status: StatusAgendamento.values.byName(j['status'] as String),
        criadoEm: DateTime.tryParse(j['criadoEm'] as String? ?? ''),
      );
}
