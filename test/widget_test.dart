// Testes das regras de negócio principais (compatibilidade e aptidão).
// Rode com: flutter test

import 'package:doa_sangue/models/doacao.dart';
import 'package:doa_sangue/models/doador.dart';
import 'package:doa_sangue/models/tipo_sanguineo.dart';
import 'package:doa_sangue/services/elegibilidade.dart';
import 'package:flutter_test/flutter_test.dart';

Doador _doador({
  Sexo sexo = Sexo.masculino,
  double peso = 70,
  DateTime? nascimento,
}) =>
    Doador(
      id: 'x',
      nome: 'Pessoa Teste',
      email: 't@t.com',
      senhaHash: '',
      salt: '',
      dataNascimento: nascimento ?? DateTime(1995, 1, 1),
      sexo: sexo,
      tipo: TipoSanguineo.oPos,
      peso: peso,
      telefone: '',
      cidade: '',
      endereco: '',
      termosAceitosEm: DateTime(2026, 1, 1),
    );

Doacao _doacao(DateTime data) =>
    Doacao(id: data.toIso8601String(), doadorId: 'x', data: data, local: 'H');

void main() {
  group('Compatibilidade sanguínea', () {
    test('O- é doador universal', () {
      expect(TipoSanguineo.oNeg.podeDoarPara.length, 8);
    });

    test('AB+ é receptor universal', () {
      expect(TipoSanguineo.abPos.podeReceberDe.length, 8);
    });

    test('A- recebe apenas de A- e O-', () {
      expect(TipoSanguineo.aNeg.podeReceberDe,
          unorderedEquals([TipoSanguineo.aNeg, TipoSanguineo.oNeg]));
    });

    test('O+ recebe de O+ e O-', () {
      expect(TipoSanguineo.oPos.podeReceberDe,
          unorderedEquals([TipoSanguineo.oPos, TipoSanguineo.oNeg]));
    });
  });

  group('Elegibilidade', () {
    final hoje = DateTime(2026, 11, 3);

    test('sem doações anteriores está apto', () {
      final r = Elegibilidade.calcular(_doador(), [], hoje: hoje);
      expect(r.aptoAgora, isTrue);
    });

    test('homem que doou há 30 dias espera mais 30', () {
      final r = Elegibilidade.calcular(
        _doador(),
        [_doacao(DateTime(2026, 10, 4))],
        hoje: hoje,
      );
      expect(r.aptoAgora, isFalse);
      expect(r.proximaData, DateTime(2026, 12, 3));
      expect(r.diasRestantes(hoje), 30);
    });

    test('mulher tem intervalo de 90 dias', () {
      final r = Elegibilidade.calcular(
        _doador(sexo: Sexo.feminino),
        [_doacao(DateTime(2026, 9, 3))],
        hoje: hoje,
      );
      expect(r.aptoAgora, isFalse);
      expect(r.proximaData, DateTime(2026, 12, 2));
    });

    test('peso abaixo de 50 kg impede a doação', () {
      final r = Elegibilidade.calcular(_doador(peso: 48), [], hoje: hoje);
      expect(r.impedido, isTrue);
      expect(r.motivos, isNotEmpty);
    });

    test('menor de 16 anos não pode doar', () {
      final r = Elegibilidade.calcular(
          _doador(nascimento: DateTime(2012, 1, 1)), [],
          hoje: hoje);
      expect(r.impedido, isTrue);
    });

    test('16 e 17 anos geram aviso de autorização', () {
      final r = Elegibilidade.calcular(
          _doador(nascimento: DateTime(2009, 6, 1)), [],
          hoje: hoje);
      expect(r.aptoAgora, isTrue);
      expect(r.avisos, isNotEmpty);
    });

    test('homem com 4 doações em 12 meses atinge o limite anual', () {
      final r = Elegibilidade.calcular(
        _doador(),
        [
          _doacao(DateTime(2026, 9, 1)),
          _doacao(DateTime(2026, 6, 25)),
          _doacao(DateTime(2026, 4, 20)),
          _doacao(DateTime(2026, 2, 15)),
        ],
        hoje: hoje,
      );
      expect(r.aptoAgora, isFalse);
      // Libera quando a doação mais antiga das 4 sair da janela de 12 meses.
      expect(r.proximaData!.isAfter(DateTime(2027, 2, 14)), isTrue);
    });
  });
}
