/// Doação realizada (RF04). Pode ser registrada pelo hemocentro ao concluir
/// um agendamento, ou informada manualmente pelo doador (doações anteriores).
class Doacao {
  Doacao({
    required this.id,
    required this.doadorId,
    required this.data,
    required this.local,
    this.instituicaoId,
    this.informadaPeloDoador = false,
  });

  final String id;
  final String doadorId;
  final DateTime data;
  final String local;
  final String? instituicaoId;
  final bool informadaPeloDoador;

  Map<String, dynamic> toJson() => {
        'id': id,
        'doadorId': doadorId,
        'data': data.toIso8601String(),
        'local': local,
        'instituicaoId': instituicaoId,
        'informadaPeloDoador': informadaPeloDoador,
      };

  factory Doacao.fromJson(Map<String, dynamic> j) => Doacao(
        id: j['id'] as String,
        doadorId: j['doadorId'] as String,
        data: DateTime.parse(j['data'] as String),
        local: j['local'] as String? ?? '',
        instituicaoId: j['instituicaoId'] as String?,
        informadaPeloDoador: j['informadaPeloDoador'] as bool? ?? false,
      );
}
