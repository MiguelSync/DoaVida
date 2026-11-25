# DoaVida — App de Conexão com Bancos de Sangue

Projeto de Extensão · **UNIDAVI** · Bacharelado em Sistemas de Informação
Disciplina: Desenvolvimento para Plataformas Móveis — Prof. Sandro Alencar Fernandes
Equipe: José Augusto Jacinto, Miguel Antonio Selhorst e Victor Ramos Marcelino
Pilar de Extensão: **V — Universidade Solidária**

Aplicativo Flutter (Android e iOS) que conecta hemocentros e hospitais do Alto Vale do Itajaí a uma base de doadores de sangue cadastrados. O hospital registra a necessidade, o app avisa os doadores compatíveis e o doador agenda a doação.

**Backend:** Firebase — Authentication (login por e-mail e senha) e Cloud Firestore (banco em tempo real, região São Paulo), projeto `doavida-b5ef1`.

---

## Como rodar

Pré-requisito: Flutter instalado (`flutter doctor` sem erros).

```bash
cd ~/Documents/ProjetosFlutter/doa_sangue
bash setup.sh        # só na primeira vez: gera android/ios/web, permissões e dependências
flutter run          # emulador Android, simulador iOS ou celular conectado
flutter run -d chrome   # versão web (ótima para tirar prints rápido)
flutter test         # testes das regras de compatibilidade e aptidão
```

> O `setup.sh` roda `flutter create .` (sem sobrescrever o código em `lib/`) e depois o script `tool/configurar_plataformas.dart`, que adiciona as permissões de localização/notificação no Android e no iOS e habilita o *desugaring* exigido pelo plugin de notificações.

### Contas de demonstração (senha `123456`)

| Perfil | E-mail | Situação |
|---|---|---|
| Doador | `doador@demo.com` | Lucas, O-, doou há 40 dias (ainda no intervalo de 60 dias) |
| Doador | `mariana@demo.com` | Mariana, A+, apta para doar |
| Hemocentro | `hemosc@demo.com` | Hemosc Blumenau — estoque de O- crítico |
| Hospital | `hrav@demo.com` | Hospital Regional Alto Vale — tem agendamentos recebidos |

Na tela de login há botões que preenchem essas contas. A base tem 5 instituições, 16 doadores, 16 doações, 11 agendamentos e 3 alertas (lista completa no [GUIA_DE_TESTE.md](GUIA_DE_TESTE.md)).

---

## Firebase

| Serviço | Uso |
|---|---|
| **Authentication** (e-mail/senha) | Login de doadores e instituições. A senha fica só no Firebase Auth, nunca no banco |
| **Cloud Firestore** | Coleções `instituicoes`, `doadores`, `doacoes`, `agendamentos`, `alertas` e `notificacoes`. O app escuta as coleções em tempo real (`snapshots()`), então tudo sincroniza entre aparelhos na hora |
| **Regras de segurança** | [`firestore.rules`](firestore.rules): o doador só lê e altera os próprios dados; só instituições veem doadores e agenda; o doador não troca tipo sanguíneo/nascimento depois do cadastro; a instituição só altera o próprio estoque e os próprios alertas |

- Configuração do app: `lib/firebase_options.dart` (mesmo formato do `flutterfire configure`).
- Acesso ao banco: `lib/services/firebase_service.dart`. As regras de negócio continuam no `AppState`.
- **Repovoar a base** (volta tudo ao estado inicial):

```bash
cd tool/seed
npm install
SENHA_ADMIN='senha-da-conta-admin' node seed.mjs
```

O script cria as contas no Auth (se ainda não existirem), apaga as coleções e grava os dados de demonstração de `tool/seed/dados_demo.mjs`. Só a conta `admin@doavida.app` pode fazer isso (ver regras).

---

## Versão online (GitHub Pages)

Demo no navegador: **https://miguelsync.github.io/DoaVida/**

A cada `push` na branch `main`, o workflow `.github/workflows/deploy-pages.yml` compila o Flutter web e publica o site automaticamente (requer *Settings → Pages → Source: GitHub Actions*).

Contas de demonstração, roteiros de teste e resultados esperados: **[GUIA_DE_TESTE.md](GUIA_DE_TESTE.md)**.

---

## Requisitos × implementação

| Requisito | Onde está | Como foi atendido |
|---|---|---|
| **RF01** Cadastro de doadores | `screens/cadastro_doador_screen.dart` | Nome, e-mail, senha, nascimento (idade), sexo, tipo sanguíneo, peso, telefone, cidade e endereço, com validação |
| **RF02** Painel de hospitais/hemocentros | `screens/instituicao/` | Login próprio, indicadores, estoque por tipo, agenda e alertas |
| **RF03** Agendamento | `screens/doador/novo_agendamento_screen.dart` | Escolha de local, dia (seg.–sáb.) e horário; respeita a data de aptidão e a lotação (2 doadores por horário). A instituição confirma, registra a doação ou marca falta |
| **RF04** Histórico e próxima doação | `services/elegibilidade.dart`, `screens/doador/historico_screen.dart` | Cálculo automático: homens 60 dias / máx. 4 por ano; mulheres 90 dias / máx. 3 por ano; idade 16–69; peso ≥ 50 kg. Barra de progresso até a próxima data |
| **RF05** Mapa com geolocalização | `screens/doador/mapa_screen.dart` | OpenStreetMap (`flutter_map`, sem chave de API) + `geolocator`; lista ordenada por distância, rota e atalho para agendar |
| **RF06** Campanhas e alertas | `screens/instituicao/novo_alerta_screen.dart` | *Estoque crítico* (escolhe os tipos em falta) ou *Urgência* (informa o tipo do paciente e o app calcula os doadores compatíveis pela tabela ABO/Rh) |
| **RF07** Notificações push | `state/app_state.dart`, `services/notification_service.dart`, `screens/doador/notificacoes_screen.dart` | O alerta gera uma notificação no Firestore para cada doador compatível; o app do doador recebe em tempo real (em qualquer aparelho), mostra um aviso, a notificação do sistema (`flutter_local_notifications`) e atualiza a central com contador de não lidas |
| **RF08** FAQ | `screens/faq_screen.dart` | Requisitos básicos, preparativos (não precisa de jejum), impedimentos temporários e definitivos — baseado no Ministério da Saúde |
| **RNF01** Flutter híbrido | — | Um único código para Android e iOS (também roda na web) |
| **RNF02** Segurança dos dados | `firestore.rules`, `services/firebase_service.dart` | Login pelo Firebase Authentication (senha com hash no servidor, nunca no banco); regras do Firestore isolam os dados de cada doador; tráfego HTTPS; instituição vê só nome reduzido, tipo e telefone de quem agendou; estatísticas apenas agregadas |
| **RNF03** LGPD | `screens/termos_screen.dart`, `screens/doador/perfil_screen.dart` | Aceite explícito obrigatório no cadastro (data e versão do termo ficam registradas); exportar dados, corrigir dados, desativar alertas e excluir a conta |
| **RNF04** UI responsiva | `widgets/shell_adaptativo.dart`, `widgets/comuns.dart` | Barra inferior no celular e menu lateral em tablet/web (≥ 720 px); grades que se ajustam à largura; conteúdo com largura máxima |
| **RNF05** Tempo de resposta ≤ 10 s | `state/app_state.dart`, `services/location_service.dart` | Carga inicial do Firestore com tempo limite de 10 s; gravações otimistas (a tela atualiza na hora e o Firestore confirma em segundo plano); a localização tem tempo limite de 10 s e o mapa funciona sem ela |

---

## Arquitetura

```
lib/
├── main.dart                  # inicialização (datas pt-BR, Firebase, notificações)
├── app.dart                   # MaterialApp + rota raiz conforme a sessão + avisos em tempo real
├── firebase_options.dart      # configuração do projeto Firebase
├── models/                    # Doador, Instituicao, Doacao, Agendamento, Alerta, Notificacao, TipoSanguineo
├── services/
│   ├── elegibilidade.dart     # regras de aptidão (RF04)
│   ├── firebase_service.dart  # Firebase Auth + Cloud Firestore (leitura em tempo real e gravação)
│   ├── notification_service.dart
│   └── location_service.dart
├── state/app_state.dart       # estado global (Provider/ChangeNotifier) e regras de negócio
├── screens/
│   ├── boas_vindas, login, cadastro_doador, termos, faq
│   ├── doador/                # início, mapa, agendamentos, histórico, perfil, notificações
│   └── instituicao/           # painel, alertas, novo alerta, agenda
├── widgets/                   # componentes reutilizáveis e shell responsivo
└── theme/tema.dart
test/widget_test.dart          # testes de compatibilidade e elegibilidade
firestore.rules                # regras de segurança do banco
tool/seed/                     # script que popula o Firebase com os dados de demonstração
```

- **Gerência de estado:** `provider` com um `AppState` (ChangeNotifier). As telas só leem o estado e chamam métodos; as regras ficam centralizadas.
- **Persistência:** Cloud Firestore. O `FirebaseService` isola o Firebase; o `AppState` escuta as coleções do perfil logado (o doador escuta só os próprios documentos) e as telas não sabem que existe um banco — foi possível trocar o armazenamento local pelo Firebase sem reescrever as telas.
- **Compatibilidade sanguínea:** tabela ABO/Rh em `models/tipo_sanguineo.dart` (`podeDoarPara` / `podeReceberDe`).

## Limitações do protótipo e próximos passos

- O aviso de alerta chega em tempo real enquanto o app está aberto (em qualquer aparelho). **Próximo passo:** Firebase Cloud Messaging + Cloud Functions para avisar também com o app fechado (exige o plano pago Blaze).
- O cadastro de novas instituições é feito pela equipe (script de carga); no futuro, um fluxo de solicitação com validação do CNES.
- As instituições têm localização aproximada e informações ilustrativas; os doadores e contatos são fictícios.
- A avaliação final de aptidão é sempre da triagem clínica do hemocentro — o app só orienta.

## Referências

- Ministério da Saúde — Doação de sangue: https://www.gov.br/saude/pt-br/composicao/saes/doacao-de-sangue
- Lei Geral de Proteção de Dados (Lei nº 13.709/2018)
- Documentação Flutter: https://docs.flutter.dev
