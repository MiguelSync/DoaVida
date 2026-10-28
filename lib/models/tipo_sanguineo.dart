/// Tipos sanguíneos (sistema ABO + fator Rh) e regras de compatibilidade
/// para doação de concentrado de hemácias.
enum TipoSanguineo {
  oNeg('O-'),
  oPos('O+'),
  aNeg('A-'),
  aPos('A+'),
  bNeg('B-'),
  bPos('B+'),
  abNeg('AB-'),
  abPos('AB+');

  const TipoSanguineo(this.label);

  /// Texto exibido na interface (ex.: "O-").
  final String label;

  /// Tipos de RECEPTOR que podem receber sangue de quem tem este tipo.
  Set<TipoSanguineo> get podeDoarPara =>
      _doaPara[this] ?? const <TipoSanguineo>{};

  /// Tipos de DOADOR compatíveis com um paciente (receptor) deste tipo.
  Set<TipoSanguineo> get podeReceberDe => TipoSanguineo.values
      .where((doador) => doador.podeDoarPara.contains(this))
      .toSet();

  bool get doadorUniversal => this == TipoSanguineo.oNeg;
  bool get receptorUniversal => this == TipoSanguineo.abPos;

  /// Ordena um conjunto de tipos na ordem padrão do enum.
  static List<TipoSanguineo> ordenar(Iterable<TipoSanguineo> tipos) {
    final set = tipos.toSet();
    return TipoSanguineo.values.where(set.contains).toList();
  }

  /// "O-, O+ e A-"
  static String juntar(Iterable<TipoSanguineo> tipos) {
    final labels = ordenar(tipos).map((t) => t.label).toList();
    if (labels.isEmpty) return '';
    if (labels.length == 1) return labels.first;
    return '${labels.sublist(0, labels.length - 1).join(', ')} e ${labels.last}';
  }
}

/// Tabela de compatibilidade de hemácias: doador -> receptores.
const Map<TipoSanguineo, Set<TipoSanguineo>> _doaPara = {
  TipoSanguineo.oNeg: {
    TipoSanguineo.oNeg,
    TipoSanguineo.oPos,
    TipoSanguineo.aNeg,
    TipoSanguineo.aPos,
    TipoSanguineo.bNeg,
    TipoSanguineo.bPos,
    TipoSanguineo.abNeg,
    TipoSanguineo.abPos,
  },
  TipoSanguineo.oPos: {
    TipoSanguineo.oPos,
    TipoSanguineo.aPos,
    TipoSanguineo.bPos,
    TipoSanguineo.abPos,
  },
  TipoSanguineo.aNeg: {
    TipoSanguineo.aNeg,
    TipoSanguineo.aPos,
    TipoSanguineo.abNeg,
    TipoSanguineo.abPos,
  },
  TipoSanguineo.aPos: {
    TipoSanguineo.aPos,
    TipoSanguineo.abPos,
  },
  TipoSanguineo.bNeg: {
    TipoSanguineo.bNeg,
    TipoSanguineo.bPos,
    TipoSanguineo.abNeg,
    TipoSanguineo.abPos,
  },
  TipoSanguineo.bPos: {
    TipoSanguineo.bPos,
    TipoSanguineo.abPos,
  },
  TipoSanguineo.abNeg: {
    TipoSanguineo.abNeg,
    TipoSanguineo.abPos,
  },
  TipoSanguineo.abPos: {
    TipoSanguineo.abPos,
  },
};
