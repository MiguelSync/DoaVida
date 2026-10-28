import '../models/doacao.dart';
import '../models/doador.dart';
import '../utils/formatos.dart';

/// Resultado do cálculo de aptidão do doador (RF04).
class ResultadoElegibilidade {
  const ResultadoElegibilidade({
    required this.aptoAgora,
    required this.proximaData,
    required this.motivos,
    required this.avisos,
    this.ultimaDoacao,
  });

  /// Pode doar hoje.
  final bool aptoAgora;

  /// Primeira data em que poderá doar. `null` = impedimento que o app não
  /// consegue prever (idade/peso fora dos limites).
  final DateTime? proximaData;

  /// Motivos que impedem a doação.
  final List<String> motivos;

  /// Observações que não impedem, mas devem ser exibidas.
  final List<String> avisos;

  final DateTime? ultimaDoacao;

  bool get impedido => proximaData == null;

  int diasRestantes([DateTime? hoje]) {
    if (proximaData == null) return 0;
    final d = diasEntre(hoje ?? DateTime.now(), proximaData!);
    return d < 0 ? 0 : d;
  }

  /// Progresso (0..1) entre a última doação e a próxima data liberada.
  double progresso([DateTime? hoje]) {
    if (aptoAgora) return 1;
    if (ultimaDoacao == null || proximaData == null) return 0;
    final total = diasEntre(ultimaDoacao!, proximaData!);
    if (total <= 0) return 1;
    final feito = diasEntre(ultimaDoacao!, hoje ?? DateTime.now());
    return (feito / total).clamp(0.0, 1.0);
  }
}

/// Regras do Ministério da Saúde usadas no protótipo:
/// - idade entre 16 e 69 anos (16–17 com autorização; 60–69 só se já doou);
/// - peso mínimo de 50 kg;
/// - intervalo: homens 60 dias (máx. 4/ano), mulheres 90 dias (máx. 3/ano).
class Elegibilidade {
  static const pesoMinimo = 50.0;
  static const idadeMinima = 16;
  static const idadeMaxima = 69;

  static int intervaloDias(Sexo sexo) => sexo == Sexo.masculino ? 60 : 90;
  static int maximoPorAno(Sexo sexo) => sexo == Sexo.masculino ? 4 : 3;

  static ResultadoElegibilidade calcular(
    Doador doador,
    List<Doacao> doacoes, {
    DateTime? hoje,
  }) {
    final dia = soData(hoje ?? DateTime.now());
    final motivos = <String>[];
    final avisos = <String>[];

    final ordenadas = [...doacoes]..sort((a, b) => b.data.compareTo(a.data));
    final ultima = ordenadas.isEmpty ? null : soData(ordenadas.first.data);

    if (doador.peso < pesoMinimo) {
      motivos.add('O peso mínimo para doar é de 50 kg.');
    }

    final idade = doador.idadeEm(dia);
    if (idade < idadeMinima) {
      motivos.add('A idade mínima para doar é de 16 anos.');
    } else if (idade > idadeMaxima) {
      motivos.add(
          'A idade máxima para doar é de 69 anos. Doadores regulares acima '
          'disso podem ser avaliados pelo hemocentro.');
    } else if (idade >= 60 && ordenadas.isEmpty) {
      motivos.add(
          'Entre 60 e 69 anos só pode doar quem já doou antes dos 60. '
          'Se você já doou, informe a doação no seu histórico.');
    }

    if (idade >= 16 && idade < 18) {
      avisos.add(
          'Menores de 18 anos precisam do consentimento formal do responsável legal.');
    }

    if (motivos.isNotEmpty) {
      return ResultadoElegibilidade(
        aptoAgora: false,
        proximaData: null,
        motivos: motivos,
        avisos: avisos,
        ultimaDoacao: ultima,
      );
    }

    var liberacao = dia;

    if (ultima != null) {
      // Intervalo mínimo entre doações.
      final porIntervalo = somarDias(ultima, intervaloDias(doador.sexo));
      if (porIntervalo.isAfter(liberacao)) liberacao = porIntervalo;

      // Limite de doações em 12 meses.
      final limite = somarDias(dia, -365);
      final noUltimoAno =
          ordenadas.where((d) => soData(d.data).isAfter(limite)).toList();
      final maximo = maximoPorAno(doador.sexo);
      if (noUltimoAno.length >= maximo) {
        final porLimite = somarDias(soData(noUltimoAno[maximo - 1].data), 366);
        if (porLimite.isAfter(liberacao)) {
          liberacao = porLimite;
          avisos.add('Você atingiu o limite de $maximo doações em 12 meses.');
        }
      }
    }

    return ResultadoElegibilidade(
      aptoAgora: !liberacao.isAfter(dia),
      proximaData: liberacao,
      motivos: motivos,
      avisos: avisos,
      ultimaDoacao: ultima,
    );
  }
}
