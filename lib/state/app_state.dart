import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/agendamento.dart';
import '../models/alerta.dart';
import '../models/doacao.dart';
import '../models/doador.dart';
import '../models/instituicao.dart';
import '../models/notificacao.dart';
import '../models/tipo_sanguineo.dart';
import '../services/elegibilidade.dart';
import '../services/notification_service.dart';
import '../services/seed_data.dart';
import '../services/seguranca.dart';
import '../services/storage_service.dart';
import '../utils/formatos.dart';

enum Papel { doador, instituicao }

/// Estado global do app (padrão Provider + ChangeNotifier).
/// Concentra as regras de negócio; as telas apenas leem e chamam métodos.
class AppState extends ChangeNotifier {
  AppState(this._storage, this._push);

  final StorageService _storage;
  final NotificationService _push;

  /// Capacidade de atendimento por horário em cada instituição.
  static const capacidadePorHorario = 2;

  List<Doador> _doadores = [];
  List<Instituicao> _instituicoes = [];
  List<Doacao> _doacoes = [];
  List<Agendamento> _agendamentos = [];
  List<Alerta> _alertas = [];
  List<Notificacao> _notificacoes = [];

  Papel? _papel;
  String? _usuarioId;

  Papel? get papel => _papel;
  String? get usuarioId => _usuarioId;
  bool get pushDisponivel => _push.disponivel;

  List<Instituicao> get instituicoes => List.unmodifiable(_instituicoes);
  int get totalDoadores => _doadores.length;

  // ---------------------------------------------------------------------------
  // Carregamento e persistência
  // ---------------------------------------------------------------------------

  Future<void> carregar() async {
    final banco = _storage.lerBanco();
    var carregou = false;
    if (banco != null) {
      try {
        _deJson(banco);
        carregou = true;
      } catch (e) {
        debugPrint('Banco local inválido, recriando dados de demonstração: $e');
      }
    }
    if (!carregou) {
      _aplicar(SeedData.gerar());
      await _storage.salvarBanco(_paraJson());
    }

    final sessao = _storage.lerSessao();
    if (sessao != null) {
      final (papelSalvo, id) = sessao;
      if (papelSalvo == Papel.doador.name && doadorPorId(id) != null) {
        _papel = Papel.doador;
        _usuarioId = id;
      } else if (papelSalvo == Papel.instituicao.name &&
          instituicaoPorId(id) != null) {
        _papel = Papel.instituicao;
        _usuarioId = id;
      }
    }
    notifyListeners();
  }

  void _aplicar(DadosIniciais d) {
    _doadores = d.doadores;
    _instituicoes = d.instituicoes;
    _doacoes = d.doacoes;
    _agendamentos = d.agendamentos;
    _alertas = d.alertas;
    _notificacoes = d.notificacoes;
  }

  Map<String, dynamic> _paraJson() => {
        'doadores': _doadores.map((e) => e.toJson()).toList(),
        'instituicoes': _instituicoes.map((e) => e.toJson()).toList(),
        'doacoes': _doacoes.map((e) => e.toJson()).toList(),
        'agendamentos': _agendamentos.map((e) => e.toJson()).toList(),
        'alertas': _alertas.map((e) => e.toJson()).toList(),
        'notificacoes': _notificacoes.map((e) => e.toJson()).toList(),
      };

  List<Map<String, dynamic>> _lista(Map<String, dynamic> banco, String chave) =>
      (banco[chave] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  void _deJson(Map<String, dynamic> b) {
    _doadores = _lista(b, 'doadores').map(Doador.fromJson).toList();
    _instituicoes = _lista(b, 'instituicoes').map(Instituicao.fromJson).toList();
    _doacoes = _lista(b, 'doacoes').map(Doacao.fromJson).toList();
    _agendamentos = _lista(b, 'agendamentos').map(Agendamento.fromJson).toList();
    _alertas = _lista(b, 'alertas').map(Alerta.fromJson).toList();
    _notificacoes = _lista(b, 'notificacoes').map(Notificacao.fromJson).toList();
    if (_instituicoes.isEmpty) throw const FormatException('sem instituições');
  }

  void _salvar() {
    _storage.salvarBanco(_paraJson());
    notifyListeners();
  }

  /// Volta todos os dados para o estado inicial de demonstração.
  Future<void> restaurarDemonstracao() async {
    _aplicar(SeedData.gerar());
    _papel = null;
    _usuarioId = null;
    await _storage.limparSessao();
    _salvar();
  }

  // ---------------------------------------------------------------------------
  // Autenticação
  // ---------------------------------------------------------------------------

  String? entrar(Papel papel, String email, String senha) {
    final e = email.trim().toLowerCase();
    if (papel == Papel.doador) {
      final d = primeiro(_doadores, (x) => x.email == e);
      if (d == null || !Seguranca.conferir(senha, d.salt, d.senhaHash)) {
        return 'E-mail ou senha inválidos.';
      }
      _iniciarSessao(papel, d.id);
    } else {
      final i = primeiro(_instituicoes, (x) => x.email == e);
      if (i == null || !Seguranca.conferir(senha, i.salt, i.senhaHash)) {
        return 'E-mail ou senha inválidos.';
      }
      _iniciarSessao(papel, i.id);
    }
    return null;
  }

  void _iniciarSessao(Papel papel, String id) {
    _papel = papel;
    _usuarioId = id;
    _storage.salvarSessao(papel.name, id);
    if (papel == Papel.doador) _push.pedirPermissao();
    notifyListeners();
  }

  Future<void> sair() async {
    _papel = null;
    _usuarioId = null;
    await _storage.limparSessao();
    notifyListeners();
  }

  bool emailEmUso(String email) {
    final e = email.trim().toLowerCase();
    return _doadores.any((d) => d.email == e) ||
        _instituicoes.any((i) => i.email == e);
  }

  /// RF01 + RNF03: cadastro do doador com aceite explícito dos termos.
  String? cadastrarDoador({
    required String nome,
    required String email,
    required String senha,
    required DateTime nascimento,
    required Sexo sexo,
    required TipoSanguineo tipo,
    required double peso,
    required String telefone,
    required String cidade,
    required String endereco,
    required bool aceitouTermos,
    required bool notificacoes,
  }) {
    if (!aceitouTermos) {
      return 'É necessário aceitar os Termos de Uso e a Política de Privacidade.';
    }
    if (emailEmUso(email)) return 'Este e-mail já está cadastrado.';
    final salt = Seguranca.gerarSalt();
    final doador = Doador(
      id: gerarId(),
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      salt: salt,
      senhaHash: Seguranca.hashSenha(senha, salt),
      dataNascimento: nascimento,
      sexo: sexo,
      tipo: tipo,
      peso: peso,
      telefone: telefone.trim(),
      cidade: cidade.trim(),
      endereco: endereco.trim(),
      notificacoes: notificacoes,
      termosAceitosEm: DateTime.now(),
    );
    _doadores.add(doador);
    _storage.salvarBanco(_paraJson());
    _iniciarSessao(Papel.doador, doador.id);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Consultas gerais
  // ---------------------------------------------------------------------------

  Doador? get doadorAtual => _papel == Papel.doador && _usuarioId != null
      ? doadorPorId(_usuarioId!)
      : null;

  Instituicao? get instituicaoAtual =>
      _papel == Papel.instituicao && _usuarioId != null
          ? instituicaoPorId(_usuarioId!)
          : null;

  Doador? doadorPorId(String id) => primeiro(_doadores, (d) => d.id == id);

  Instituicao? instituicaoPorId(String id) =>
      primeiro(_instituicoes, (i) => i.id == id);

  // ---------------------------------------------------------------------------
  // Doador: perfil e LGPD
  // ---------------------------------------------------------------------------

  void atualizarDoador({
    required String nome,
    required double peso,
    required String telefone,
    required String cidade,
    required String endereco,
  }) {
    final d = doadorAtual;
    if (d == null) return;
    d
      ..nome = nome.trim()
      ..peso = peso
      ..telefone = telefone.trim()
      ..cidade = cidade.trim()
      ..endereco = endereco.trim();
    _salvar();
  }

  void definirNotificacoes(bool ativo) {
    final d = doadorAtual;
    if (d == null) return;
    d.notificacoes = ativo;
    if (ativo) _push.pedirPermissao();
    _salvar();
  }

  /// LGPD art. 18, II: acesso aos dados.
  String exportarDadosDoador() {
    final d = doadorAtual;
    if (d == null) return '{}';
    final dados = {
      'dadosPessoais': d.dadosPessoais(),
      'doacoes': doacoesDe(d.id)
          .map((x) => {
                'data': x.data.toIso8601String(),
                'local': x.local,
                'informadaPeloDoador': x.informadaPeloDoador,
              })
          .toList(),
      'agendamentos': agendamentosDoDoador(d.id)
          .map((a) => {
                'dataHora': a.dataHora.toIso8601String(),
                'local': instituicaoPorId(a.instituicaoId)?.nome,
                'status': a.status.label,
              })
          .toList(),
      'notificacoesRecebidas': notificacoesDe(d.id).length,
    };
    return const JsonEncoder.withIndent('  ').convert(dados);
  }

  /// LGPD art. 18, VI: eliminação dos dados pessoais.
  Future<void> excluirContaDoador() async {
    final d = doadorAtual;
    if (d == null) return;
    _doadores.removeWhere((x) => x.id == d.id);
    _doacoes.removeWhere((x) => x.doadorId == d.id);
    _agendamentos.removeWhere((x) => x.doadorId == d.id);
    _notificacoes.removeWhere((x) => x.doadorId == d.id);
    await _storage.salvarBanco(_paraJson());
    await sair();
  }

  // ---------------------------------------------------------------------------
  // Doações e elegibilidade (RF04)
  // ---------------------------------------------------------------------------

  List<Doacao> doacoesDe(String doadorId) =>
      _doacoes.where((x) => x.doadorId == doadorId).toList()
        ..sort((a, b) => b.data.compareTo(a.data));

  ResultadoElegibilidade elegibilidadeDe(Doador d) =>
      Elegibilidade.calcular(d, doacoesDe(d.id));

  /// Doador informa uma doação feita antes de usar o app.
  void informarDoacao(DateTime data, String local) {
    final d = doadorAtual;
    if (d == null) return;
    _doacoes.add(Doacao(
      id: gerarId(),
      doadorId: d.id,
      data: data,
      local: local.trim().isEmpty ? 'Local não informado' : local.trim(),
      informadaPeloDoador: true,
    ));
    _salvar();
  }

  void removerDoacaoInformada(String id) {
    _doacoes.removeWhere((x) => x.id == id && x.informadaPeloDoador);
    _salvar();
  }

  // ---------------------------------------------------------------------------
  // Agendamentos (RF03)
  // ---------------------------------------------------------------------------

  List<Agendamento> agendamentosDoDoador(String doadorId) =>
      _agendamentos.where((a) => a.doadorId == doadorId).toList()
        ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

  Agendamento? agendamentoAtivoDe(String doadorId) {
    final ativos = _agendamentos
        .where((a) => a.doadorId == doadorId && a.status.ativo)
        .toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return ativos.isEmpty ? null : ativos.first;
  }

  List<Agendamento> agendamentosDaInstituicao(String instituicaoId) =>
      _agendamentos.where((a) => a.instituicaoId == instituicaoId).toList()
        ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

  int ocupacao(String instituicaoId, DateTime dataHora) => _agendamentos
      .where((a) =>
          a.instituicaoId == instituicaoId &&
          a.status.ativo &&
          a.dataHora == dataHora)
      .length;

  String? agendar(String instituicaoId, DateTime dataHora) {
    final d = doadorAtual;
    if (d == null) return 'Faça login novamente.';
    if (agendamentoAtivoDe(d.id) != null) {
      return 'Você já tem um agendamento ativo. Cancele-o para marcar outro.';
    }
    final eleg = elegibilidadeDe(d);
    if (eleg.proximaData == null) {
      return 'No momento você não atende aos requisitos para doar.';
    }
    if (soData(dataHora).isBefore(eleg.proximaData!)) {
      return 'Pelo intervalo entre doações, você só pode doar a partir de '
          '${fData(eleg.proximaData!)}.';
    }
    if (!dataHora.isAfter(DateTime.now())) {
      return 'Escolha um horário futuro.';
    }
    if (ocupacao(instituicaoId, dataHora) >= capacidadePorHorario) {
      return 'Este horário acabou de lotar. Escolha outro.';
    }
    _agendamentos.add(Agendamento(
      id: gerarId(),
      doadorId: d.id,
      instituicaoId: instituicaoId,
      dataHora: dataHora,
      status: StatusAgendamento.agendado,
    ));
    _salvar();
    return null;
  }

  void cancelarAgendamento(String id) => alterarStatus(id, StatusAgendamento.cancelado);

  /// Usado pelo painel da instituição: confirmar, registrar doação, falta.
  void alterarStatus(String agendamentoId, StatusAgendamento status) {
    final a = primeiro(_agendamentos, (x) => x.id == agendamentoId);
    if (a == null) return;
    a.status = status;
    if (status == StatusAgendamento.realizado) {
      final agora = DateTime.now();
      _doacoes.add(Doacao(
        id: gerarId(),
        doadorId: a.doadorId,
        data: a.dataHora.isAfter(agora) ? agora : a.dataHora,
        local: instituicaoPorId(a.instituicaoId)?.nome ?? 'Instituição',
        instituicaoId: a.instituicaoId,
      ));
    }
    _salvar();
  }

  // ---------------------------------------------------------------------------
  // Instituição: estoque e alertas (RF02, RF06, RF07)
  // ---------------------------------------------------------------------------

  void definirEstoque(TipoSanguineo tipo, NivelEstoque nivel) {
    final i = instituicaoAtual;
    if (i == null) return;
    i.estoque[tipo] = nivel;
    _salvar();
  }

  Map<TipoSanguineo, int> doadoresPorTipo() => {
        for (final t in TipoSanguineo.values)
          t: _doadores.where((d) => d.tipo == t).length,
      };

  /// Doadores que serão avisados (tipo compatível + notificações ativas).
  List<Doador> doadoresParaTipos(Set<TipoSanguineo> tipos) => _doadores
      .where((d) => tipos.contains(d.tipo) && d.notificacoes)
      .toList();

  List<Alerta> alertasDaInstituicao(String instituicaoId) =>
      _alertas.where((a) => a.instituicaoId == instituicaoId).toList()
        ..sort((a, b) {
          if (a.ativo != b.ativo) return a.ativo ? -1 : 1;
          return b.criadoEm.compareTo(a.criadoEm);
        });

  List<Alerta> alertasAtivosPara(Doador d) => _alertas
      .where((a) => a.ativo && a.tiposNecessarios.contains(d.tipo))
      .toList()
    ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

  /// Publica o alerta e notifica todos os doadores compatíveis.
  /// Retorna quantos doadores foram notificados.
  Future<int> publicarAlerta({
    required TipoAlerta tipo,
    required String titulo,
    required String mensagem,
    required Set<TipoSanguineo> tipos,
  }) async {
    final inst = instituicaoAtual;
    if (inst == null || tipos.isEmpty) return 0;
    final alvo = doadoresParaTipos(tipos);
    final alerta = Alerta(
      id: gerarId(),
      instituicaoId: inst.id,
      tipo: tipo,
      titulo: titulo,
      mensagem: mensagem,
      tiposNecessarios: tipos,
      criadoEm: DateTime.now(),
      notificados: alvo.length,
    );
    _alertas.add(alerta);
    for (final d in alvo) {
      _notificacoes.add(Notificacao(
        id: gerarId(),
        doadorId: d.id,
        alertaId: alerta.id,
        titulo: titulo,
        corpo: '${inst.nome}: $mensagem',
        criadaEm: alerta.criadoEm,
      ));
    }
    _salvar();
    if (alvo.isNotEmpty) {
      // Simula o push que chegaria no celular dos doadores compatíveis.
      await _push.mostrar(titulo, '${inst.nome} · $mensagem');
    }
    return alvo.length;
  }

  void encerrarAlerta(String id) {
    final a = primeiro(_alertas, (x) => x.id == id);
    if (a == null) return;
    a.ativo = false;
    _salvar();
  }

  // ---------------------------------------------------------------------------
  // Notificações do doador
  // ---------------------------------------------------------------------------

  List<Notificacao> notificacoesDe(String doadorId) =>
      _notificacoes.where((n) => n.doadorId == doadorId).toList()
        ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm));

  int naoLidasDe(String doadorId) =>
      _notificacoes.where((n) => n.doadorId == doadorId && !n.lida).length;

  void marcarLida(String id) {
    final n = primeiro(_notificacoes, (x) => x.id == id);
    if (n == null || n.lida) return;
    n.lida = true;
    _salvar();
  }

  void marcarTodasLidas(String doadorId) {
    for (final n in _notificacoes.where((x) => x.doadorId == doadorId)) {
      n.lida = true;
    }
    _salvar();
  }
}
