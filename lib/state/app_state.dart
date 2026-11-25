import 'dart:async';
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
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../utils/formatos.dart';

enum Papel { doador, instituicao }

/// Estado global do app (padrão Provider + ChangeNotifier).
/// Concentra as regras de negócio; as telas apenas leem e chamam métodos.
class AppState extends ChangeNotifier {
  AppState(this._fb, this._push);

  final FirebaseService _fb;
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
  bool _carregando = true;

  final _mensagens = StreamController<String>.broadcast();
  final _novas = StreamController<Notificacao>.broadcast();

  Papel? get papel => _papel;
  String? get usuarioId => _usuarioId;
  bool get carregando => _carregando;
  bool get pushDisponivel => _push.disponivel;

  /// Avisos para a interface (ex.: falha ao gravar no Firestore).
  Stream<String> get mensagens => _mensagens.stream;

  /// Notificações que chegaram em tempo real enquanto o app está aberto.
  Stream<Notificacao> get novasNotificacoes => _novas.stream;

  List<Instituicao> get instituicoes => List.unmodifiable(_instituicoes);
  int get totalDoadores => _doadores.length;

  // ---------------------------------------------------------------------------
  // Carregamento: sessão do Firebase Auth + escutas em tempo real do Firestore
  // ---------------------------------------------------------------------------

  Future<void> carregar() async {
    try {
      final usuario = await _fb.usuarioInicial();
      if (usuario != null) {
        final erro = await _abrirSessao(usuario.uid);
        if (erro != null) await _fb.sair();
      }
    } catch (e) {
      debugPrint('Falha ao restaurar a sessão: $e');
    }
    _carregando = false;
    notifyListeners();
  }

  /// Descobre o perfil do usuário logado, carrega os dados dele e liga as
  /// escutas em tempo real. Retorna uma mensagem de erro ou null.
  Future<String?> _abrirSessao(String uid, {Papel? esperado}) async {
    final inst = await _fb.documento(Colecoes.instituicoes, uid);
    final Papel papel;
    if (inst != null) {
      papel = Papel.instituicao;
      _instituicoes = [Instituicao.fromJson(inst)];
    } else {
      final doc = await _fb.documento(Colecoes.doadores, uid);
      if (doc == null) return 'Cadastro não encontrado para esta conta.';
      papel = Papel.doador;
      _doadores = [Doador.fromJson(doc)];
    }
    if (esperado != null && esperado != papel) {
      _limparDados();
      return papel == Papel.doador
          ? 'Esta conta é de doador. Use "Sou doador" para entrar.'
          : 'Esta conta é de uma instituição. Use o acesso institucional.';
    }
    await _ligarEscutas(papel, uid);
    _papel = papel;
    _usuarioId = uid;
    if (papel == Papel.doador) _push.pedirPermissao();
    notifyListeners();
    return null;
  }

  Future<void> _ligarEscutas(Papel papel, String uid) async {
    await _fb.pararEscutas();
    final pendentes = <Completer<void>>[];

    void escutar(
      String colecao,
      void Function(LoteFirestore) aplicar, {
      String? campo,
      Object? igualA,
      String? documento,
    }) {
      final pronto = Completer<void>();
      pendentes.add(pronto);
      void aoMudar(LoteFirestore lote) {
        try {
          aplicar(lote);
        } catch (e) {
          debugPrint('Dado inválido em $colecao: $e');
        }
        if (!pronto.isCompleted) pronto.complete();
        notifyListeners();
      }

      void aoErrar(Object e) {
        if (!pronto.isCompleted) pronto.complete();
      }

      if (documento != null) {
        _fb.escutarDocumento(colecao, documento, aoMudar, aoErrar: aoErrar);
      } else {
        _fb.escutar(colecao, aoMudar,
            campo: campo, igualA: igualA, aoErrar: aoErrar);
      }
    }

    List<T> converter<T>(
            LoteFirestore l, T Function(Map<String, dynamic>) fromJson) =>
        l.documentos.map(fromJson).toList();

    escutar(Colecoes.instituicoes,
        (l) => _instituicoes = converter(l, Instituicao.fromJson));
    escutar(Colecoes.agendamentos,
        (l) => _agendamentos = converter(l, Agendamento.fromJson));
    escutar(Colecoes.alertas, (l) => _alertas = converter(l, Alerta.fromJson));

    if (papel == Papel.doador) {
      escutar(Colecoes.doadores, documento: uid, (l) {
        _doadores = converter(l, Doador.fromJson);
        // Conta apagada em outro aparelho: encerra a sessão.
        if (_doadores.isEmpty && !l.inicial) sair();
      });
      escutar(Colecoes.doacoes, campo: 'doadorId', igualA: uid,
          (l) => _doacoes = converter(l, Doacao.fromJson));
      escutar(Colecoes.notificacoes, campo: 'doadorId', igualA: uid, (l) {
        _notificacoes = converter(l, Notificacao.fromJson);
        if (l.inicial) return;
        // Chegou um alerta novo publicado por uma instituição (RF07).
        for (final n in l.adicionados.map(Notificacao.fromJson)) {
          _novas.add(n);
          _push.mostrar(n.titulo, n.corpo);
        }
      });
    } else {
      escutar(Colecoes.doadores,
          (l) => _doadores = converter(l, Doador.fromJson));
      escutar(Colecoes.doacoes,
          (l) => _doacoes = converter(l, Doacao.fromJson));
      _notificacoes = [];
    }

    // RNF05: não deixa o usuário esperando mais que 10 s.
    await Future.wait(pendentes.map((c) => c.future))
        .timeout(const Duration(seconds: 10), onTimeout: () => []);
  }

  void _limparDados() {
    _doadores = [];
    _instituicoes = [];
    _doacoes = [];
    _agendamentos = [];
    _alertas = [];
    _notificacoes = [];
  }

  /// Grava no Firestore sem travar a tela; se falhar, avisa a interface.
  void _gravar(Future<void> operacao) {
    operacao.catchError((Object e) {
      _mensagens.add(FirebaseService.mensagemErro(e));
    });
  }

  // ---------------------------------------------------------------------------
  // Autenticação (Firebase Authentication)
  // ---------------------------------------------------------------------------

  Future<String?> entrar(Papel papel, String email, String senha) async {
    try {
      final uid = await _fb.entrar(email, senha);
      final erro = await _abrirSessao(uid, esperado: papel);
      if (erro != null) await _fb.sair();
      return erro;
    } catch (e) {
      return FirebaseService.mensagemErro(e);
    }
  }

  Future<void> sair() async {
    await _fb.pararEscutas();
    _papel = null;
    _usuarioId = null;
    _limparDados();
    notifyListeners();
    await _fb.sair();
  }

  /// RF01 + RNF03: cadastro do doador com aceite explícito dos termos.
  /// A senha fica no Firebase Authentication (nunca no banco de dados).
  Future<String?> cadastrarDoador({
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
  }) async {
    if (!aceitouTermos) {
      return 'É necessário aceitar os Termos de Uso e a Política de Privacidade.';
    }
    try {
      final uid = await _fb.criarConta(email, senha);
      final doador = Doador(
        id: uid,
        nome: nome.trim(),
        email: email.trim().toLowerCase(),
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
      await _fb.salvar(Colecoes.doadores, uid, doador.toJson());
      return await _abrirSessao(uid, esperado: Papel.doador);
    } catch (e) {
      return FirebaseService.mensagemErro(e);
    }
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
    notifyListeners();
    _gravar(_fb.atualizar(Colecoes.doadores, d.id, {
      'nome': d.nome,
      'peso': d.peso,
      'telefone': d.telefone,
      'cidade': d.cidade,
      'endereco': d.endereco,
    }));
  }

  void definirNotificacoes(bool ativo) {
    final d = doadorAtual;
    if (d == null) return;
    d.notificacoes = ativo;
    if (ativo) _push.pedirPermissao();
    notifyListeners();
    _gravar(_fb.atualizar(Colecoes.doadores, d.id, {'notificacoes': ativo}));
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

  /// LGPD art. 18, VI: eliminação dos dados pessoais (Firestore + login).
  /// Retorna uma mensagem de erro ou null.
  Future<String?> excluirContaDoador() async {
    final d = doadorAtual;
    if (d == null) return null;
    try {
      await _fb.pararEscutas();
      await _fb.excluirLote([
        for (final x in _doacoes.where((x) => x.doadorId == d.id))
          (Colecoes.doacoes, x.id),
        for (final x in _agendamentos.where((x) => x.doadorId == d.id))
          (Colecoes.agendamentos, x.id),
        for (final x in _notificacoes.where((x) => x.doadorId == d.id))
          (Colecoes.notificacoes, x.id),
        (Colecoes.doadores, d.id),
      ]);
      await _fb.excluirUsuario();
    } catch (e) {
      final msg = FirebaseService.mensagemErro(e);
      await sair();
      return msg;
    }
    await sair();
    return null;
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
    final doacao = Doacao(
      id: _fb.novoId(Colecoes.doacoes),
      doadorId: d.id,
      data: data,
      local: local.trim().isEmpty ? 'Local não informado' : local.trim(),
      informadaPeloDoador: true,
    );
    _doacoes.add(doacao);
    notifyListeners();
    _gravar(_fb.salvar(Colecoes.doacoes, doacao.id, doacao.toJson()));
  }

  void removerDoacaoInformada(String id) {
    _doacoes.removeWhere((x) => x.id == id && x.informadaPeloDoador);
    notifyListeners();
    _gravar(_fb.excluir(Colecoes.doacoes, id));
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
    final ag = Agendamento(
      id: _fb.novoId(Colecoes.agendamentos),
      doadorId: d.id,
      instituicaoId: instituicaoId,
      dataHora: dataHora,
      status: StatusAgendamento.agendado,
    );
    _agendamentos.add(ag);
    notifyListeners();
    _gravar(_fb.salvar(Colecoes.agendamentos, ag.id, ag.toJson()));
    return null;
  }

  void cancelarAgendamento(String id) => alterarStatus(id, StatusAgendamento.cancelado);

  /// Usado pelo painel da instituição: confirmar, registrar doação, falta.
  void alterarStatus(String agendamentoId, StatusAgendamento status) {
    final a = primeiro(_agendamentos, (x) => x.id == agendamentoId);
    if (a == null) return;
    a.status = status;
    _gravar(_fb.atualizar(
        Colecoes.agendamentos, a.id, {'status': status.name}));
    if (status == StatusAgendamento.realizado) {
      final agora = DateTime.now();
      final doacao = Doacao(
        id: _fb.novoId(Colecoes.doacoes),
        doadorId: a.doadorId,
        data: a.dataHora.isAfter(agora) ? agora : a.dataHora,
        local: instituicaoPorId(a.instituicaoId)?.nome ?? 'Instituição',
        instituicaoId: a.instituicaoId,
      );
      _doacoes.add(doacao);
      _gravar(_fb.salvar(Colecoes.doacoes, doacao.id, doacao.toJson()));
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Instituição: estoque e alertas (RF02, RF06, RF07)
  // ---------------------------------------------------------------------------

  void definirEstoque(TipoSanguineo tipo, NivelEstoque nivel) {
    final i = instituicaoAtual;
    if (i == null) return;
    i.estoque[tipo] = nivel;
    notifyListeners();
    _gravar(_fb.atualizar(Colecoes.instituicoes, i.id, {
      'estoque': {for (final e in i.estoque.entries) e.key.name: e.value.name},
    }));
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
      id: _fb.novoId(Colecoes.alertas),
      instituicaoId: inst.id,
      tipo: tipo,
      titulo: titulo,
      mensagem: mensagem,
      tiposNecessarios: tipos,
      criadoEm: DateTime.now(),
      notificados: alvo.length,
    );
    final notificacoes = [
      for (final d in alvo)
        Notificacao(
          id: _fb.novoId(Colecoes.notificacoes),
          doadorId: d.id,
          alertaId: alerta.id,
          titulo: titulo,
          corpo: '${inst.nome}: $mensagem',
          criadaEm: alerta.criadoEm,
        ),
    ];
    // Alerta + uma notificação por doador compatível, gravados juntos.
    // Cada doador recebe a sua em tempo real pela escuta do Firestore.
    await _fb.salvarLote([
      (Colecoes.alertas, alerta.id, alerta.toJson()),
      for (final n in notificacoes) (Colecoes.notificacoes, n.id, n.toJson()),
    ]);
    if (!_alertas.any((a) => a.id == alerta.id)) _alertas.add(alerta);
    notifyListeners();
    return alvo.length;
  }

  void encerrarAlerta(String id) {
    final a = primeiro(_alertas, (x) => x.id == id);
    if (a == null) return;
    a.ativo = false;
    notifyListeners();
    _gravar(_fb.atualizar(Colecoes.alertas, id, {'ativo': false}));
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
    notifyListeners();
    _gravar(_fb.atualizar(Colecoes.notificacoes, id, {'lida': true}));
  }

  void marcarTodasLidas(String doadorId) {
    final naoLidas =
        _notificacoes.where((x) => x.doadorId == doadorId && !x.lida).toList();
    for (final n in naoLidas) {
      n.lida = true;
    }
    notifyListeners();
    _gravar(_fb.salvarLote([
      for (final n in naoLidas) (Colecoes.notificacoes, n.id, n.toJson()),
    ]));
  }

  @override
  void dispose() {
    _fb.pararEscutas();
    _mensagens.close();
    _novas.close();
    super.dispose();
  }
}
