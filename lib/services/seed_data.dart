import '../models/agendamento.dart';
import '../models/alerta.dart';
import '../models/doacao.dart';
import '../models/doador.dart';
import '../models/instituicao.dart';
import '../models/notificacao.dart';
import '../models/tipo_sanguineo.dart';
import '../utils/formatos.dart';
import 'seguranca.dart';

class DadosIniciais {
  DadosIniciais({
    required this.doadores,
    required this.instituicoes,
    required this.doacoes,
    required this.agendamentos,
    required this.alertas,
    required this.notificacoes,
  });

  final List<Doador> doadores;
  final List<Instituicao> instituicoes;
  final List<Doacao> doacoes;
  final List<Agendamento> agendamentos;
  final List<Alerta> alertas;
  final List<Notificacao> notificacoes;
}

/// Dados de DEMONSTRAÇÃO para apresentar o protótipo.
/// Instituições com localização aproximada e informações ilustrativas;
/// doadores e contatos são fictícios.
class SeedData {
  static const senhaDemo = '123456';

  static DadosIniciais gerar() {
    final hoje = soData(DateTime.now());

    // Dia relativo a hoje; pula domingo (instituições fechadas).
    DateTime diaUtil(int delta, [int hora = 0, int minuto = 0]) {
      var d = DateTime(hoje.year, hoje.month, hoje.day + delta, hora, minuto);
      while (d.weekday == DateTime.sunday) {
        d = somarDias(d, delta >= 0 ? 1 : -1);
      }
      return d;
    }

    DateTime dia(int delta) => somarDias(hoje, delta);

    Instituicao inst({
      required String id,
      required String nome,
      required TipoInstituicao tipo,
      required String cidade,
      required String horario,
      required double lat,
      required double lng,
      required String email,
      Map<TipoSanguineo, NivelEstoque> excecoes = const {},
    }) {
      final salt = Seguranca.gerarSalt();
      return Instituicao(
        id: id,
        nome: nome,
        tipo: tipo,
        cidade: cidade,
        horario: horario,
        lat: lat,
        lng: lng,
        email: email,
        salt: salt,
        senhaHash: Seguranca.hashSenha(senhaDemo, salt),
        estoque: {
          for (final t in TipoSanguineo.values)
            t: excecoes[t] ?? NivelEstoque.estavel,
        },
      );
    }

    Doador doador({
      required String id,
      required String nome,
      required String email,
      required DateTime nascimento,
      required Sexo sexo,
      required TipoSanguineo tipo,
      required double peso,
      String cidade = 'Rio do Sul',
    }) {
      final salt = Seguranca.gerarSalt();
      return Doador(
        id: id,
        nome: nome,
        email: email,
        salt: salt,
        senhaHash: Seguranca.hashSenha(senhaDemo, salt),
        dataNascimento: nascimento,
        sexo: sexo,
        tipo: tipo,
        peso: peso,
        telefone: '(47) 99999-0000',
        cidade: cidade,
        endereco: 'Endereço de exemplo, 100 - Centro',
        termosAceitosEm: dia(-200),
        criadoEm: dia(-200),
      );
    }

    final instituicoes = [
      inst(
        id: 'i1',
        nome: 'Hemosc Blumenau',
        tipo: TipoInstituicao.hemocentro,
        cidade: 'Blumenau',
        horario: 'Seg. a sex., 7h às 18h · Sáb., 8h às 12h',
        lat: -26.9187,
        lng: -49.0698,
        email: 'hemosc@demo.com',
        excecoes: {
          TipoSanguineo.oNeg: NivelEstoque.critico,
          TipoSanguineo.oPos: NivelEstoque.baixo,
          TipoSanguineo.aNeg: NivelEstoque.baixo,
        },
      ),
      inst(
        id: 'i2',
        nome: 'Hospital Regional Alto Vale',
        tipo: TipoInstituicao.hospital,
        cidade: 'Rio do Sul',
        horario: 'Seg. a sex., 8h às 16h30 · Sáb., 8h às 12h',
        lat: -27.2083,
        lng: -49.6379,
        email: 'hrav@demo.com',
        excecoes: {
          TipoSanguineo.bNeg: NivelEstoque.critico,
          TipoSanguineo.oNeg: NivelEstoque.baixo,
        },
      ),
      inst(
        id: 'i3',
        nome: 'Hospital Samária',
        tipo: TipoInstituicao.hospital,
        cidade: 'Rio do Sul',
        horario: 'Seg. a sex., 8h às 16h30',
        lat: -27.2165,
        lng: -49.6455,
        email: 'samaria@demo.com',
        excecoes: {TipoSanguineo.abNeg: NivelEstoque.baixo},
      ),
      inst(
        id: 'i4',
        nome: 'Hospital Bom Jesus',
        tipo: TipoInstituicao.hospital,
        cidade: 'Ituporanga',
        horario: 'Seg. a sex., 8h às 16h30',
        lat: -27.4106,
        lng: -49.5983,
        email: 'bomjesus@demo.com',
        excecoes: {TipoSanguineo.aPos: NivelEstoque.baixo},
      ),
      inst(
        id: 'i5',
        nome: 'Coleta Itinerante UNIDAVI',
        tipo: TipoInstituicao.hemocentro,
        cidade: 'Rio do Sul',
        horario: 'Sáb., 8h às 12h (campanhas)',
        lat: -27.2017,
        lng: -49.6324,
        email: 'coleta@demo.com',
        excecoes: {TipoSanguineo.oNeg: NivelEstoque.critico},
      ),
    ];

    final doadores = [
      doador(
        id: 'd1',
        nome: 'Lucas Pereira',
        email: 'doador@demo.com',
        nascimento: DateTime(1999, 5, 12),
        sexo: Sexo.masculino,
        tipo: TipoSanguineo.oNeg,
        peso: 78,
      ),
      doador(
        id: 'd2',
        nome: 'Mariana Costa',
        email: 'mariana@demo.com',
        nascimento: DateTime(1996, 9, 3),
        sexo: Sexo.feminino,
        tipo: TipoSanguineo.aPos,
        peso: 62,
      ),
      doador(
          id: 'd3',
          nome: 'Ana Souza',
          email: 'ana@demo.com',
          nascimento: DateTime(2001, 2, 20),
          sexo: Sexo.feminino,
          tipo: TipoSanguineo.oPos,
          peso: 58),
      doador(
          id: 'd4',
          nome: 'Bruno Schmitt',
          email: 'bruno@demo.com',
          nascimento: DateTime(1988, 11, 8),
          sexo: Sexo.masculino,
          tipo: TipoSanguineo.bNeg,
          peso: 84,
          cidade: 'Ituporanga'),
      doador(
          id: 'd5',
          nome: 'Carla Hoffmann',
          email: 'carla@demo.com',
          nascimento: DateTime(1993, 7, 14),
          sexo: Sexo.feminino,
          tipo: TipoSanguineo.abPos,
          peso: 66),
      doador(
          id: 'd6',
          nome: 'Diego Ramos',
          email: 'diego@demo.com',
          nascimento: DateTime(2000, 1, 30),
          sexo: Sexo.masculino,
          tipo: TipoSanguineo.oNeg,
          peso: 72,
          cidade: 'Blumenau'),
      doador(
          id: 'd7',
          nome: 'Elisa Kraus',
          email: 'elisa@demo.com',
          nascimento: DateTime(1998, 4, 2),
          sexo: Sexo.feminino,
          tipo: TipoSanguineo.aNeg,
          peso: 55),
      doador(
          id: 'd8',
          nome: 'Felipe Moser',
          email: 'felipe@demo.com',
          nascimento: DateTime(1985, 10, 19),
          sexo: Sexo.masculino,
          tipo: TipoSanguineo.oPos,
          peso: 90,
          cidade: 'Blumenau'),
      doador(
          id: 'd9',
          nome: 'Gabriela Lenz',
          email: 'gabriela@demo.com',
          nascimento: DateTime(2002, 12, 1),
          sexo: Sexo.feminino,
          tipo: TipoSanguineo.bPos,
          peso: 60),
      doador(
          id: 'd10',
          nome: 'Henrique Beduschi',
          email: 'henrique@demo.com',
          nascimento: DateTime(1991, 6, 25),
          sexo: Sexo.masculino,
          tipo: TipoSanguineo.aPos,
          peso: 81,
          cidade: 'Ituporanga'),
    ];

    final doacoes = [
      // Lucas: 3 doações no último ano, a última há 40 dias (apto em ~20 dias).
      Doacao(
          id: 'dc1',
          doadorId: 'd1',
          data: diaUtil(-40, 9),
          local: 'Hospital Regional Alto Vale',
          instituicaoId: 'i2'),
      Doacao(
          id: 'dc2',
          doadorId: 'd1',
          data: diaUtil(-160, 10),
          local: 'Hemosc Blumenau',
          instituicaoId: 'i1'),
      Doacao(
          id: 'dc3',
          doadorId: 'd1',
          data: diaUtil(-300, 8),
          local: 'Coleta Itinerante UNIDAVI',
          informadaPeloDoador: true),
      // Mariana: última há 120 dias (apta).
      Doacao(
          id: 'dc4',
          doadorId: 'd2',
          data: diaUtil(-120, 14),
          local: 'Hospital Samária',
          instituicaoId: 'i3'),
      Doacao(
          id: 'dc5',
          doadorId: 'd8',
          data: diaUtil(-70, 11),
          local: 'Hemosc Blumenau',
          instituicaoId: 'i1'),
    ];

    final agendamentos = [
      Agendamento(
          id: 'ag1',
          doadorId: 'd1',
          instituicaoId: 'i2',
          dataHora: doacoes[0].data,
          status: StatusAgendamento.realizado,
          criadoEm: dia(-45)),
      Agendamento(
          id: 'ag2',
          doadorId: 'd2',
          instituicaoId: 'i2',
          dataHora: diaUtil(2, 9),
          status: StatusAgendamento.agendado,
          criadoEm: dia(-1)),
      Agendamento(
          id: 'ag3',
          doadorId: 'd3',
          instituicaoId: 'i2',
          dataHora: diaUtil(1, 10, 30),
          status: StatusAgendamento.confirmado,
          criadoEm: dia(-3)),
      Agendamento(
          id: 'ag4',
          doadorId: 'd5',
          instituicaoId: 'i2',
          dataHora: diaUtil(3, 14),
          status: StatusAgendamento.agendado,
          criadoEm: dia(0)),
      Agendamento(
          id: 'ag5',
          doadorId: 'd6',
          instituicaoId: 'i1',
          dataHora: diaUtil(2, 8, 30),
          status: StatusAgendamento.agendado,
          criadoEm: dia(-2)),
    ];

    final tiposAlerta = {TipoSanguineo.oNeg, TipoSanguineo.oPos};
    final alvo =
        doadores.where((d) => tiposAlerta.contains(d.tipo) && d.notificacoes);
    final alerta = Alerta(
      id: 'al1',
      instituicaoId: 'i1',
      tipo: TipoAlerta.campanha,
      titulo: 'Estoque crítico de O- e O+',
      mensagem:
          'Nossos estoques de sangue tipo O estão muito baixos. Agende sua doação!',
      tiposNecessarios: tiposAlerta,
      criadoEm: somarDias(DateTime.now(), -1),
      notificados: alvo.length,
    );

    final notificacoes = [
      for (final d in alvo)
        Notificacao(
          id: 'n_${d.id}',
          doadorId: d.id,
          alertaId: alerta.id,
          titulo: alerta.titulo,
          corpo: 'Hemosc Blumenau: ${alerta.mensagem}',
          criadaEm: alerta.criadoEm,
        ),
    ];

    return DadosIniciais(
      doadores: doadores,
      instituicoes: instituicoes,
      doacoes: doacoes,
      agendamentos: agendamentos,
      alertas: [alerta],
      notificacoes: notificacoes,
    );
  }
}
