import 'package:flutter/material.dart';

import '../models/agendamento.dart';
import '../models/instituicao.dart';

class AppCores {
  static const vermelho = Color(0xFFC62828);
  static const vermelhoEscuro = Color(0xFF8E1B1B);
  static const fundo = Color(0xFFFBF7F6);
  static const borda = Color(0xFFEDE3E1);
  static const texto = Color(0xFF2B1D1C);
  static const textoSuave = Color(0xFF7A6A68);

  static const critico = Color(0xFFD32F2F);
  static const baixo = Color(0xFFEF6C00);
  static const estavel = Color(0xFF2E7D32);
  static const info = Color(0xFF1565C0);

  static Color nivel(NivelEstoque n) => switch (n) {
        NivelEstoque.critico => critico,
        NivelEstoque.baixo => baixo,
        NivelEstoque.estavel => estavel,
      };

  static Color status(StatusAgendamento s) => switch (s) {
        StatusAgendamento.agendado => baixo,
        StatusAgendamento.confirmado => info,
        StatusAgendamento.realizado => estavel,
        StatusAgendamento.cancelado => textoSuave,
        StatusAgendamento.faltou => critico,
      };
}

class AppTema {
  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: AppCores.vermelho,
      primary: AppCores.vermelho,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppCores.fundo,
    );
  }
}
