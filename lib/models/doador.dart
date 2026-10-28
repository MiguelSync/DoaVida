import 'tipo_sanguineo.dart';

enum Sexo {
  masculino('Masculino'),
  feminino('Feminino');

  const Sexo(this.label);
  final String label;
}

/// Doador cadastrado no app (RF01).
class Doador {
  Doador({
    required this.id,
    required this.nome,
    required this.email,
    required this.senhaHash,
    required this.salt,
    required this.dataNascimento,
    required this.sexo,
    required this.tipo,
    required this.peso,
    required this.telefone,
    required this.cidade,
    required this.endereco,
    required this.termosAceitosEm,
    this.versaoTermos = '1.0',
    this.notificacoes = true,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  final String id;
  String nome;
  final String email;
  final String senhaHash;
  final String salt;
  final DateTime dataNascimento;
  final Sexo sexo;
  final TipoSanguineo tipo;
  double peso;
  String telefone;
  String cidade;
  String endereco;

  /// Se o doador aceita receber alertas/campanhas (RF07).
  bool notificacoes;

  /// Registro do consentimento LGPD (RNF03).
  final DateTime termosAceitosEm;
  final String versaoTermos;
  final DateTime criadoEm;

  int idadeEm(DateTime data) {
    var idade = data.year - dataNascimento.year;
    final aindaNaoFezAniversario = data.month < dataNascimento.month ||
        (data.month == dataNascimento.month && data.day < dataNascimento.day);
    if (aindaNaoFezAniversario) idade--;
    return idade;
  }

  int get idade => idadeEm(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'senhaHash': senhaHash,
        'salt': salt,
        'dataNascimento': dataNascimento.toIso8601String(),
        'sexo': sexo.name,
        'tipo': tipo.name,
        'peso': peso,
        'telefone': telefone,
        'cidade': cidade,
        'endereco': endereco,
        'notificacoes': notificacoes,
        'termosAceitosEm': termosAceitosEm.toIso8601String(),
        'versaoTermos': versaoTermos,
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory Doador.fromJson(Map<String, dynamic> j) => Doador(
        id: j['id'] as String,
        nome: j['nome'] as String,
        email: j['email'] as String,
        senhaHash: j['senhaHash'] as String,
        salt: j['salt'] as String,
        dataNascimento: DateTime.parse(j['dataNascimento'] as String),
        sexo: Sexo.values.byName(j['sexo'] as String),
        tipo: TipoSanguineo.values.byName(j['tipo'] as String),
        peso: (j['peso'] as num).toDouble(),
        telefone: j['telefone'] as String? ?? '',
        cidade: j['cidade'] as String? ?? '',
        endereco: j['endereco'] as String? ?? '',
        notificacoes: j['notificacoes'] as bool? ?? true,
        termosAceitosEm: DateTime.parse(j['termosAceitosEm'] as String),
        versaoTermos: j['versaoTermos'] as String? ?? '1.0',
        criadoEm: DateTime.tryParse(j['criadoEm'] as String? ?? ''),
      );

  /// Dados pessoais legíveis, sem credenciais — usado na exportação (LGPD art. 18).
  Map<String, dynamic> dadosPessoais() => {
        'nome': nome,
        'email': email,
        'dataNascimento': dataNascimento.toIso8601String().substring(0, 10),
        'sexo': sexo.label,
        'tipoSanguineo': tipo.label,
        'pesoKg': peso,
        'telefone': telefone,
        'cidade': cidade,
        'endereco': endereco,
        'recebeNotificacoes': notificacoes,
        'termosAceitosEm': termosAceitosEm.toIso8601String(),
        'versaoTermos': versaoTermos,
        'contaCriadaEm': criadoEm.toIso8601String(),
      };
}
