import 'tipo_sanguineo.dart';

enum TipoInstituicao {
  hemocentro('Hemocentro'),
  hospital('Hospital');

  const TipoInstituicao(this.label);
  final String label;
}

enum NivelEstoque {
  critico('Crítico'),
  baixo('Baixo'),
  estavel('Estável');

  const NivelEstoque(this.label);
  final String label;
}

/// Hospital ou hemocentro com acesso ao painel institucional (RF02).
class Instituicao {
  Instituicao({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.cidade,
    required this.horario,
    required this.lat,
    required this.lng,
    required this.email,
    required this.senhaHash,
    required this.salt,
    required this.estoque,
  });

  final String id;
  final String nome;
  final TipoInstituicao tipo;
  final String cidade;
  final String horario;
  final double lat;
  final double lng;
  final String email;
  final String senhaHash;
  final String salt;

  /// Nível de estoque por tipo sanguíneo (alimenta os alertas — RF06).
  final Map<TipoSanguineo, NivelEstoque> estoque;

  NivelEstoque nivel(TipoSanguineo t) => estoque[t] ?? NivelEstoque.estavel;

  List<TipoSanguineo> tiposNoNivel(NivelEstoque n) =>
      TipoSanguineo.values.where((t) => nivel(t) == n).toList();

  bool get temEstoqueCritico => tiposNoNivel(NivelEstoque.critico).isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo.name,
        'cidade': cidade,
        'horario': horario,
        'lat': lat,
        'lng': lng,
        'email': email,
        'senhaHash': senhaHash,
        'salt': salt,
        'estoque': {
          for (final e in estoque.entries) e.key.name: e.value.name,
        },
      };

  factory Instituicao.fromJson(Map<String, dynamic> j) {
    final bruto = Map<String, dynamic>.from(j['estoque'] as Map? ?? {});
    return Instituicao(
      id: j['id'] as String,
      nome: j['nome'] as String,
      tipo: TipoInstituicao.values.byName(j['tipo'] as String),
      cidade: j['cidade'] as String,
      horario: j['horario'] as String? ?? '',
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      email: j['email'] as String,
      senhaHash: j['senhaHash'] as String,
      salt: j['salt'] as String,
      estoque: {
        for (final e in bruto.entries)
          TipoSanguineo.values.byName(e.key):
              NivelEstoque.values.byName(e.value as String),
      },
    );
  }
}
