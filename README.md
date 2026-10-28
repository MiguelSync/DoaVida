# DoaVida — App de Conexão com Bancos de Sangue

Projeto de Extensão · **UNIDAVI** · Bacharelado em Sistemas de Informação
Disciplina: Desenvolvimento para Plataformas Móveis — Prof. Sandro Alencar Fernandes
Equipe: José Augusto Jacinto, Miguel Antonio Selhorst e Victor Ramos Marcelino
Pilar de Extensão: **V — Universidade Solidária**

Aplicativo Flutter (Android e iOS) que conecta hemocentros e hospitais do Alto Vale do Itajaí a uma base de doadores de sangue cadastrados. O hospital registra a necessidade, o app avisa os doadores compatíveis e o doador agenda a doação.

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

Na tela de login há botões que preenchem essas contas. No painel da instituição, o menu ⋮ → **Restaurar demonstração** volta tudo ao estado inicial.

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
| **RF07** Notificações push | `services/notification_service.dart`, `screens/doador/notificacoes_screen.dart` | Notificação do sistema (`flutter_local_notifications`) + central de notificações com contador de não lidas |
| **RF08** FAQ | `screens/faq_screen.dart` | Requisitos básicos, preparativos (não precisa de jejum), impedimentos temporários e definitivos — baseado no Ministério da Saúde |
| **RNF01** Flutter híbrido | — | Um único código para Android e iOS (também roda na web) |
| **RNF02** Segurança dos dados | `services/seguranca.dart` | Senhas com SHA-256 + salt aleatório e 1000 iterações; perfis separados; instituição vê só nome reduzido, tipo e telefone de quem agendou; estatísticas de doadores apenas agregadas |
| **RNF03** LGPD | `screens/termos_screen.dart`, `screens/doador/perfil_screen.dart` | Aceite explícito obrigatório no cadastro (data e versão do termo ficam registradas); exportar dados, corrigir dados, desativar alertas e excluir a conta |
| **RNF04** UI responsiva | `widgets/shell_adaptativo.dart`, `widgets/comuns.dart` | Barra inferior no celular e menu lateral em tablet/web (≥ 720 px); grades que se ajustam à largura; conteúdo com largura máxima |
| **RNF05** Tempo de resposta ≤ 10 s | `services/location_service.dart` | Dados locais carregam instantaneamente; a localização tem tempo limite de 10 s e o mapa funciona mesmo sem ela |

---

## Arquitetura

```
lib/
├── main.dart                  # inicialização (datas pt-BR, storage, notificações)
├── app.dart                   # MaterialApp + rota raiz conforme a sessão
├── models/                    # Doador, Instituicao, Doacao, Agendamento, Alerta, Notificacao, TipoSanguineo
├── services/
│   ├── elegibilidade.dart     # regras de aptidão (RF04)
│   ├── seguranca.dart         # hash de senha (RNF02)
│   ├── storage_service.dart   # persistência local (shared_preferences)
│   ├── notification_service.dart
│   ├── location_service.dart
│   └── seed_data.dart         # dados de demonstração
├── state/app_state.dart       # estado global (Provider/ChangeNotifier) e regras de negócio
├── screens/
│   ├── boas_vindas, login, cadastro_doador, termos, faq
│   ├── doador/                # início, mapa, agendamentos, histórico, perfil, notificações
│   └── instituicao/           # painel, alertas, novo alerta, agenda
├── widgets/                   # componentes reutilizáveis e shell responsivo
└── theme/tema.dart
test/widget_test.dart          # testes de compatibilidade e elegibilidade
```

- **Gerência de estado:** `provider` com um `AppState` (ChangeNotifier). As telas só leem o estado e chamam métodos; as regras ficam centralizadas.
- **Persistência:** todo o "banco" é salvo em JSON localmente. A camada `StorageService` isola isso, então trocar por Firebase/API depois não exige mexer nas telas.
- **Compatibilidade sanguínea:** tabela ABO/Rh em `models/tipo_sanguineo.dart` (`podeDoarPara` / `podeReceberDe`).

## Limitações do protótipo e próximos passos

- Os dados ficam no próprio aparelho. Por isso a notificação de um alerta aparece no mesmo dispositivo em que a instituição publicou — é uma simulação do push. **Próximo passo:** Firebase Auth + Cloud Firestore + Firebase Cloud Messaging para sincronizar entre aparelhos.
- As instituições têm localização aproximada e informações ilustrativas; os doadores e contatos são fictícios.
- A avaliação final de aptidão é sempre da triagem clínica do hemocentro — o app só orienta.

## Referências

- Ministério da Saúde — Doação de sangue: https://www.gov.br/saude/pt-br/composicao/saes/doacao-de-sangue
- Lei Geral de Proteção de Dados (Lei nº 13.709/2018)
- Documentação Flutter: https://docs.flutter.dev
