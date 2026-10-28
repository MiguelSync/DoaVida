import 'package:flutter/material.dart';

import '../models/tipo_sanguineo.dart';
import '../theme/tema.dart';

/// Decoração padrão dos campos de formulário.
InputDecoration campo(
  String rotulo, {
  IconData? icone,
  String? dica,
  String? sufixo,
  String? ajuda,
}) =>
    InputDecoration(
      labelText: rotulo,
      hintText: dica,
      suffixText: sufixo,
      helperText: ajuda,
      helperMaxLines: 2,
      prefixIcon: icone == null ? null : Icon(icone),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppCores.borda),
      ),
    );

/// Selo circular com o tipo sanguíneo.
class TipoBadge extends StatelessWidget {
  const TipoBadge(
    this.tipo, {
    super.key,
    this.tamanho = 40,
    this.preenchido = true,
    this.claro = false,
  });

  final TipoSanguineo tipo;
  final double tamanho;
  final bool preenchido;

  /// Fundo branco com texto vermelho (para usar sobre fundos vermelhos).
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final Color fundo;
    final Color texto;
    if (claro) {
      fundo = Colors.white;
      texto = AppCores.vermelho;
    } else if (preenchido) {
      fundo = AppCores.vermelho;
      texto = Colors.white;
    } else {
      fundo = AppCores.vermelho.withValues(alpha: 0.08);
      texto = AppCores.vermelho;
    }
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fundo,
        shape: BoxShape.circle,
        border: preenchido || claro
            ? null
            : Border.all(color: AppCores.vermelho.withValues(alpha: 0.35)),
      ),
      child: Text(
        tipo.label,
        style: TextStyle(
          color: texto,
          fontWeight: FontWeight.w800,
          fontSize: tamanho * 0.36,
        ),
      ),
    );
  }
}

/// Lista horizontal de selos pequenos.
class TiposLinha extends StatelessWidget {
  const TiposLinha(this.tipos, {super.key, this.tamanho = 30});
  final Iterable<TipoSanguineo> tipos;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final t in TipoSanguineo.ordenar(tipos))
          TipoBadge(t, tamanho: tamanho, preenchido: false),
      ],
    );
  }
}

/// Etiqueta colorida (status, nível de estoque etc.).
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, required this.cor, this.icone});
  final String texto;
  final Color cor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão branco com borda suave e toque opcional.
class Cartao extends StatelessWidget {
  const Cartao({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.cor,
    this.corBorda,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? cor;
  final Color? corBorda;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cor ?? Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: corBorda ?? AppCores.borda),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.acao, this.subtitulo});
  final String texto;
  final String? subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto,
                    style: tema.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitulo!,
                        style: tema.bodySmall
                            ?.copyWith(color: AppCores.textoSuave)),
                  ),
              ],
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.texto,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String? texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Cartao(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          Icon(icone, size: 40, color: AppCores.vermelho.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (texto != null) ...[
            const SizedBox(height: 4),
            Text(texto!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppCores.textoSuave)),
          ],
          if (acao != null) ...[const SizedBox(height: 14), acao!],
        ],
      ),
    );
  }
}

/// Indicador numérico (painel da instituição, impacto do doador).
class Indicador extends StatelessWidget {
  const Indicador({
    super.key,
    required this.icone,
    required this.valor,
    required this.rotulo,
    this.cor = AppCores.vermelho,
  });

  final IconData icone;
  final String valor;
  final String rotulo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Cartao(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                Text(rotulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppCores.textoSuave)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Distribui filhos em colunas de acordo com a largura disponível (RNF04).
class GradeResponsiva extends StatelessWidget {
  const GradeResponsiva({
    super.key,
    required this.children,
    this.larguraMinima = 160,
    this.maxColunas = 4,
    this.espaco = 10,
  });

  final List<Widget> children;
  final double larguraMinima;
  final int maxColunas;
  final double espaco;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      var colunas = (c.maxWidth / larguraMinima).floor();
      if (colunas < 1) colunas = 1;
      if (colunas > maxColunas) colunas = maxColunas;
      final largura = (c.maxWidth - espaco * (colunas - 1)) / colunas;
      return Wrap(
        spacing: espaco,
        runSpacing: espaco,
        children: [
          for (final w in children) SizedBox(width: largura, child: w),
        ],
      );
    });
  }
}

/// Limita a largura do conteúdo em tablets/web e centraliza.
class ConteudoLimitado extends StatelessWidget {
  const ConteudoLimitado({super.key, required this.child, this.maxLargura = 960});
  final Widget child;
  final double maxLargura;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxLargura),
        child: child,
      ),
    );
  }
}

/// Lista rolável padrão das telas, já com largura limitada.
class PaginaLista extends StatelessWidget {
  const PaginaLista({super.key, required this.children, this.maxLargura = 960});
  final List<Widget> children;
  final double maxLargura;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ConteudoLimitado(
          maxLargura: maxLargura,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String botao = 'Confirmar',
  bool perigoso = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Voltar'),
        ),
        FilledButton(
          style: perigoso
              ? FilledButton.styleFrom(backgroundColor: AppCores.critico)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(botao),
        ),
      ],
    ),
  );
  return r ?? false;
}

void avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}
