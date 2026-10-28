# Guia de teste — DoaVida

Como abrir o app, quais contas usar e o que esperar em cada fluxo.

## Onde abrir

| Forma | Como |
|---|---|
| **Online (GitHub Pages)** | https://miguelsync.github.io/DoaVida/ |
| **Local, no navegador** | `flutter run -d chrome` |
| **Local, no celular/emulador** | `flutter run` |
| **Testes automatizados** | `flutter test` |

> Os dados de demonstração ficam salvos **no próprio navegador** (ou aparelho). Cada pessoa que abre o app enxerga os seus dados, e nada sincroniza entre aparelhos. Para voltar ao estado inicial: entre como instituição → menu **⋮** → **Restaurar demonstração**.

## Contas de demonstração

**Senha de todas: `123456`**

Na tela de login há botões que preenchem a conta (só para as duas primeiras de cada perfil). As demais você digita o e-mail.

### Doadores

| E-mail | Quem é | Situação inicial |
|---|---|---|
| `doador@demo.com` | Lucas · O- · homem | 3 doações; a última foi há ~40 dias, então só pode doar de novo em ~20 dias. Tem 1 notificação não lida |
| `mariana@demo.com` | Mariana · A+ · mulher | Apta. Tem um agendamento no Hospital Regional daqui a 2 dias (aguardando confirmação) |
| `elisa@demo.com` | Elisa · A- · mulher | Apta, sem doações e sem agendamentos — **ideal para o ciclo completo** |
| `ana@demo.com` | Ana · O+ · mulher | Agendamento **confirmado** amanhã no Hospital Regional |
| `bruno@demo.com` | Bruno · B- | Apto |
| `carla@demo.com` | Carla · AB+ | Agendamento aguardando confirmação no Hospital Regional |
| `diego@demo.com` | Diego · O- | Agendamento aguardando confirmação no Hemosc |
| `felipe@demo.com` · `gabriela@demo.com` · `henrique@demo.com` | O+ · B+ · A+ | Aptos |

### Hospitais e hemocentros

| E-mail | Instituição | Situação inicial |
|---|---|---|
| `hemosc@demo.com` | Hemosc Blumenau (hemocentro) | O- **crítico**; O+ e A- baixos; 1 alerta ativo já publicado |
| `hrav@demo.com` | Hospital Regional Alto Vale | B- **crítico**; O- baixo; 3 agendamentos (Ana confirmada, Mariana e Carla aguardando) |
| `samaria@demo.com` · `bomjesus@demo.com` · `coleta@demo.com` | Outras instituições | Sem agendamentos |

---

## Roteiro rápido (5 minutos)

1. Abra o app → **Quero doar sangue** → entre com `doador@demo.com`. Veja a tela inicial, o sino com 1 notificação e o cartão laranja com a data da próxima doação.
2. Aba **Mapa**: aceite a localização (ou recuse — o mapa continua funcionando).
3. Aba **Perfil** → **Sair**.
4. **Sou hospital ou hemocentro** → entre com `hrav@demo.com`. Veja o painel, o estoque e a aba **Agenda**.

---

## Fluxos detalhados

### A) Doador que ainda não pode doar — `doador@demo.com`

- **Início:** cartão laranja "Próxima doação a partir de …", com barra de progresso do intervalo de 60 dias.
- **Alertas para o tipo O-:** aparece a campanha do Hemosc. O botão **Quero ajudar** abre o agendamento já com o Hemosc escolhido.
- **Agendar:** o calendário só libera datas a partir da próxima data de aptidão. Domingos ficam bloqueados.
- **Histórico:** 3 doações, indicadores e a regra aplicada (60 dias, máx. 4 por ano).
- **Sino (canto superior direito):** 1 notificação não lida. Ao abrir o sino e tocar na notificação, ela é marcada como lida.

### B) Ciclo completo: agendar → confirmar → registrar → histórico — `elisa@demo.com` + `hrav@demo.com`

1. Entre como **Elisa** → aba **Agenda** → **Novo agendamento**.
2. Escolha **Hospital Regional Alto Vale**, um dia e um horário (08:00 a 16:30; cada horário comporta 2 doadores) → **Confirmar**. Aparece o aviso "Doação agendada!". Depois **Sair** (aba Perfil).
3. Entre como **`hrav@demo.com`** → aba **Agenda** → **Próximos**. Aparece "Elisa K." aguardando confirmação → **Confirmar**.
4. No mesmo cartão, agora aparece **Registrar doação** → confirme.
5. Saia e entre como **Elisa** de novo → aba **Histórico**: a doação aparece como "Registrada pela instituição" e a próxima doação passa para **90 dias** depois (regra para mulheres).

> Para testar só o registro, use a Ana: ela já tem agendamento confirmado no Hospital Regional.

### C) Alerta de urgência com compatibilidade — `hrav@demo.com`

1. Aba **Alertas** → **Publicar novo alerta** → **Urgência**.
2. Escolha o tipo do paciente, por exemplo **B-**. O app mostra que o paciente B- pode receber de **O- e B-** e quantos doadores serão avisados (3: Lucas, Diego e Bruno).
3. **Publicar e notificar**. Aparece "Alerta publicado! 3 doadores compatíveis foram notificados".
4. Menu **⋮** → **Sair**. Entre como `doador@demo.com`: o sino agora mostra 2 e o alerta novo aparece na tela inicial.
5. Entre como `mariana@demo.com` (A+): **não** recebe nada, porque A+ não é compatível com paciente B-.

> Outro caminho: na aba **Painel**, toque no estoque de um tipo e mude para **Crítico** → o aviso "Criar alerta" leva ao formulário já preenchido. O painel também mostra um botão **Alertar** quando existe tipo crítico.

### D) Cadastro e bloqueios

1. **Quero doar sangue** → **Quero me cadastrar como doador**.
2. O botão **Criar minha conta** só habilita depois de marcar o aceite dos Termos (LGPD). Leia os termos pelo link.
3. Preencha com e-mail novo. Teste os bloqueios:
   - **Peso 48 kg** → a conta é criada, mas a tela inicial mostra "No momento você não pode doar" e o agendamento fica bloqueado.
   - **Nascimento há menos de 16 anos** → também bloqueado.
   - **16 ou 17 anos** → pode doar, com aviso de autorização do responsável.
4. Tente cadastrar de novo com um e-mail já usado (por exemplo `doador@demo.com`) → "Este e-mail já está cadastrado".

### E) Privacidade e LGPD — aba **Perfil**

- **Exportar meus dados:** mostra tudo o que o app guarda sobre o doador, com botão de copiar.
- **Alertas de campanhas:** desligue o interruptor e refaça o fluxo C — esse doador deixa de ser notificado e a contagem cai.
- **Termos de Uso:** mostra a data e a versão do aceite.
- **Excluir minha conta:** apaga o doador e tudo ligado a ele. Para testar sem perder a demo, use uma conta criada no fluxo D.
- No painel do hospital, os doadores aparecem só com **nome reduzido** ("Elisa K."), tipo e telefone.

### F) Responsividade (RNF04)

- Janela larga (≥ 720 px): menu lateral. Janela estreita: barra inferior.
- Para ver como celular no Chrome: `Cmd + Option + I` e depois `Cmd + Shift + M`.

### G) FAQ

Disponível sem login (tela de boas-vindas → "Quem pode doar?") e dentro do app (Início → Atalhos, ou Perfil).

---

## Sobre notificações

- **No celular (Android/iOS):** o alerta aparece como notificação do sistema, no mesmo aparelho onde o hospital publicou (simulação do push) e também na central do app.
- **Na web (GitHub Pages):** só a central de notificações (sino). A notificação do sistema não é usada no navegador.
- Push real entre aparelhos diferentes exigiria servidor (Firebase). Está listado como próximo passo no README.

## Prints sugeridos para a Entrega 1

1. Boas-vindas · 2. Login · 3. Cadastro com aceite dos termos · 4. Início do doador · 5. Mapa · 6. Agendamento (dia e horários) · 7. Histórico · 8. Perfil/LGPD · 9. FAQ · 10. Painel do hospital (estoque) · 11. Novo alerta de urgência (compatibilidade) · 12. Agenda do hospital · 13. Central de notificações
