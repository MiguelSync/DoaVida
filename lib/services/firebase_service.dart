import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Coleções do Cloud Firestore usadas pelo app.
///
/// Estrutura (todos os documentos guardam também o próprio `id`):
/// - `instituicoes/{uid}`  → hemocentros e hospitais (id = uid do Firebase Auth)
/// - `doadores/{uid}`      → doadores cadastrados (id = uid do Firebase Auth)
/// - `doacoes/{id}`        → doações realizadas ou informadas pelo doador
/// - `agendamentos/{id}`   → horários marcados pelos doadores
/// - `alertas/{id}`        → campanhas e urgências publicadas pelas instituições
/// - `notificacoes/{id}`   → caixa de entrada de cada doador
class Colecoes {
  static const instituicoes = 'instituicoes';
  static const doadores = 'doadores';
  static const doacoes = 'doacoes';
  static const agendamentos = 'agendamentos';
  static const alertas = 'alertas';
  static const notificacoes = 'notificacoes';
}

/// Mudança recebida em tempo real de uma coleção.
class LoteFirestore {
  LoteFirestore(this.colecao, this.documentos, this.adicionados, this.inicial);

  final String colecao;

  /// Estado completo atual da consulta.
  final List<Map<String, dynamic>> documentos;

  /// Documentos que acabaram de chegar (útil para avisar o doador).
  final List<Map<String, dynamic>> adicionados;

  /// `true` no primeiro retorno da consulta (carga inicial).
  final bool inicial;
}

/// Camada de acesso ao Firebase (Auth + Cloud Firestore).
///
/// Substitui o antigo `StorageService` (shared_preferences): as telas e as
/// regras de negócio continuam no `AppState`, que só conversa com esta classe.
class FirebaseService {
  FirebaseService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final List<StreamSubscription<dynamic>> _escutas = [];

  User? get usuario => _auth.currentUser;

  /// Primeiro estado de autenticação (sessão salva no aparelho/navegador).
  Future<User?> usuarioInicial() => _auth.authStateChanges().first;

  // ---------------------------------------------------------------------------
  // Autenticação (Firebase Authentication — e-mail e senha)
  // ---------------------------------------------------------------------------

  Future<String> entrar(String email, String senha) async {
    final c = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(), password: senha);
    return c.user!.uid;
  }

  Future<String> criarConta(String email, String senha) async {
    final c = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(), password: senha);
    return c.user!.uid;
  }

  Future<void> sair() => _auth.signOut();

  Future<void> excluirUsuario() async => _auth.currentUser?.delete();

  /// Mensagens em português para os erros do Firebase Auth.
  static String mensagemErro(Object e) {
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-login-credentials' =>
          'E-mail ou senha inválidos.',
        'invalid-email' => 'E-mail inválido.',
        'email-already-in-use' => 'Este e-mail já está cadastrado.',
        'weak-password' => 'A senha precisa ter pelo menos 6 caracteres.',
        'too-many-requests' =>
          'Muitas tentativas. Aguarde alguns minutos e tente de novo.',
        'network-request-failed' => 'Sem conexão com a internet.',
        'requires-recent-login' =>
          'Por segurança, saia e entre novamente antes de excluir a conta.',
        _ => 'Não foi possível concluir (${e.code}).',
      };
    }
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return 'Você não tem permissão para esta ação.';
      }
      if (e.code == 'unavailable') return 'Sem conexão com o servidor.';
      return 'Erro no servidor (${e.code}).';
    }
    return 'Erro inesperado: $e';
  }

  // ---------------------------------------------------------------------------
  // Leitura
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> documento(String colecao, String id) async {
    final snap = await _db.collection(colecao).doc(id).get();
    return snap.exists ? _comId(snap) : null;
  }

  /// Escuta uma coleção inteira ou filtrada por um campo (tempo real).
  void escutar(
    String colecao,
    void Function(LoteFirestore lote) aoMudar, {
    String? campo,
    Object? igualA,
    void Function(Object erro)? aoErrar,
  }) {
    Query<Map<String, dynamic>> q = _db.collection(colecao);
    if (campo != null) q = q.where(campo, isEqualTo: igualA);
    var inicial = true;
    _escutas.add(q.snapshots().listen((snap) {
      final docs = snap.docs.map(_comId).toList();
      final novos = snap.docChanges
          .where((c) => c.type == DocumentChangeType.added)
          .map((c) => _comId(c.doc))
          .toList();
      aoMudar(LoteFirestore(colecao, docs, novos, inicial));
      inicial = false;
    }, onError: (Object e) {
      debugPrint('Firestore ($colecao): $e');
      aoErrar?.call(e);
    }));
  }

  /// Escuta um único documento (ex.: o próprio perfil do doador).
  void escutarDocumento(
    String colecao,
    String id,
    void Function(LoteFirestore lote) aoMudar, {
    void Function(Object erro)? aoErrar,
  }) {
    var inicial = true;
    _escutas.add(_db.collection(colecao).doc(id).snapshots().listen((snap) {
      final docs = snap.exists ? [_comId(snap)] : <Map<String, dynamic>>[];
      aoMudar(LoteFirestore(colecao, docs, const [], inicial));
      inicial = false;
    }, onError: (Object e) {
      debugPrint('Firestore ($colecao/$id): $e');
      aoErrar?.call(e);
    }));
  }

  Future<void> pararEscutas() async {
    for (final e in _escutas) {
      await e.cancel();
    }
    _escutas.clear();
  }

  // ---------------------------------------------------------------------------
  // Escrita
  // ---------------------------------------------------------------------------

  Future<void> salvar(String colecao, String id, Map<String, dynamic> dados) =>
      _db.collection(colecao).doc(id).set(dados);

  Future<void> atualizar(
          String colecao, String id, Map<String, dynamic> campos) =>
      _db.collection(colecao).doc(id).update(campos);

  Future<void> excluir(String colecao, String id) =>
      _db.collection(colecao).doc(id).delete();

  /// Grava vários documentos de uma vez (tudo ou nada).
  Future<void> salvarLote(
      List<(String colecao, String id, Map<String, dynamic> dados)> itens) async {
    for (var i = 0; i < itens.length; i += 450) {
      final lote = _db.batch();
      for (final (colecao, id, dados) in itens.skip(i).take(450)) {
        lote.set(_db.collection(colecao).doc(id), dados);
      }
      await lote.commit();
    }
  }

  Future<void> excluirLote(List<(String colecao, String id)> itens) async {
    for (var i = 0; i < itens.length; i += 450) {
      final lote = _db.batch();
      for (final (colecao, id) in itens.skip(i).take(450)) {
        lote.delete(_db.collection(colecao).doc(id));
      }
      await lote.commit();
    }
  }

  /// Gera um id novo do Firestore sem gravar nada.
  String novoId(String colecao) => _db.collection(colecao).doc().id;

  static Map<String, dynamic> _comId(DocumentSnapshot<Map<String, dynamic>> s) =>
      {...?s.data(), 'id': s.id};
}
