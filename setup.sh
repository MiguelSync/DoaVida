#!/usr/bin/env bash
# Prepara o projeto para rodar: gera as pastas android/ios/web,
# aplica as permissões nativas e baixa as dependências.
# Uso: ./setup.sh   (ou: bash setup.sh)
set -e
cd "$(dirname "$0")"

echo "==> 1/3 Gerando pastas de plataforma (android, ios, web)..."
flutter create --org br.edu.unidavi --project-name doa_sangue \
  --platforms=android,ios,web .

echo "==> 2/3 Ajustando permissões e configurações nativas..."
dart tool/configurar_plataformas.dart

echo "==> 3/3 Baixando dependências..."
flutter pub get

echo ""
echo "Pronto! Para rodar:"
echo "  flutter run              # escolhe o dispositivo conectado/emulador"
echo "  flutter run -d chrome    # versão web (rápido para tirar prints)"
echo "  flutter test             # testes das regras de negócio"
