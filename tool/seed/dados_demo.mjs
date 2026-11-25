// Dados de DEMONSTRAÇÃO do DoaVida para o Firebase (Auth + Firestore).
//
// Instituições com localização aproximada e informações ilustrativas;
// doadores e contatos são fictícios. Todas as contas usam a senha 123456.
//
// Este módulo não importa o SDK: recebe as funções do Firebase por parâmetro,
// para rodar tanto no Node (seed.mjs) quanto no console do navegador.

export const SENHA_DEMO = '123456';
export const EMAIL_ADMIN = 'admin@doavida.app';

const pad = (n) => String(n).padStart(2, '0');

// Mesmo formato do DateTime.toIso8601String() do Dart (horário local).
const iso = (d) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}` +
  `T${pad(d.getHours())}:${pad(d.getMinutes())}:00.000`;

function hoje() {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

/** Dia relativo a hoje (pula domingo, quando as instituições fecham). */
function diaUtil(delta, hora = 0, minuto = 0) {
  const h = hoje();
  let d = new Date(h.getFullYear(), h.getMonth(), h.getDate() + delta, hora, minuto);
  while (d.getDay() === 0) {
    d = new Date(d.getFullYear(), d.getMonth(), d.getDate() + (delta >= 0 ? 1 : -1), hora, minuto);
  }
  return d;
}

const dia = (delta) => diaUtil(delta);
const TIPOS = ['oNeg', 'oPos', 'aNeg', 'aPos', 'bNeg', 'bPos', 'abNeg', 'abPos'];

export const INSTITUICOES = [
  {
    chave: 'i1', nome: 'Hemosc Blumenau', tipo: 'hemocentro', cidade: 'Blumenau',
    horario: 'Seg. a sex., 7h às 18h · Sáb., 8h às 12h',
    lat: -26.9187, lng: -49.0698, email: 'hemosc@demo.com',
    excecoes: { oNeg: 'critico', oPos: 'baixo', aNeg: 'baixo' },
  },
  {
    chave: 'i2', nome: 'Hospital Regional Alto Vale', tipo: 'hospital', cidade: 'Rio do Sul',
    horario: 'Seg. a sex., 8h às 16h30 · Sáb., 8h às 12h',
    lat: -27.2083, lng: -49.6379, email: 'hrav@demo.com',
    excecoes: { bNeg: 'critico', oNeg: 'baixo' },
  },
  {
    chave: 'i3', nome: 'Hospital Samária', tipo: 'hospital', cidade: 'Rio do Sul',
    horario: 'Seg. a sex., 8h às 16h30',
    lat: -27.2165, lng: -49.6455, email: 'samaria@demo.com',
    excecoes: { abNeg: 'baixo' },
  },
  {
    chave: 'i4', nome: 'Hospital Bom Jesus', tipo: 'hospital', cidade: 'Ituporanga',
    horario: 'Seg. a sex., 8h às 16h30',
    lat: -27.4106, lng: -49.5983, email: 'bomjesus@demo.com',
    excecoes: { aPos: 'baixo' },
  },
  {
    chave: 'i5', nome: 'Coleta Itinerante UNIDAVI', tipo: 'hemocentro', cidade: 'Rio do Sul',
    horario: 'Sáb., 8h às 12h (campanhas)',
    lat: -27.2017, lng: -49.6324, email: 'coleta@demo.com',
    excecoes: { oNeg: 'critico' },
  },
];

// [chave, nome, e-mail, nascimento, sexo, tipo, peso, cidade, recebe alertas]
export const DOADORES = [
  ['d1', 'Lucas Pereira', 'doador@demo.com', '1999-05-12', 'masculino', 'oNeg', 78, 'Rio do Sul', true],
  ['d2', 'Mariana Costa', 'mariana@demo.com', '1996-09-03', 'feminino', 'aPos', 62, 'Rio do Sul', true],
  ['d3', 'Ana Souza', 'ana@demo.com', '2001-02-20', 'feminino', 'oPos', 58, 'Rio do Sul', true],
  ['d4', 'Bruno Schmitt', 'bruno@demo.com', '1988-11-08', 'masculino', 'bNeg', 84, 'Ituporanga', true],
  ['d5', 'Carla Hoffmann', 'carla@demo.com', '1993-07-14', 'feminino', 'abPos', 66, 'Rio do Sul', true],
  ['d6', 'Diego Ramos', 'diego@demo.com', '2000-01-30', 'masculino', 'oNeg', 72, 'Blumenau', true],
  ['d7', 'Elisa Kraus', 'elisa@demo.com', '1998-04-02', 'feminino', 'aNeg', 55, 'Rio do Sul', true],
  ['d8', 'Felipe Moser', 'felipe@demo.com', '1985-10-19', 'masculino', 'oPos', 90, 'Blumenau', true],
  ['d9', 'Gabriela Lenz', 'gabriela@demo.com', '2002-12-01', 'feminino', 'bPos', 60, 'Rio do Sul', true],
  ['d10', 'Henrique Beduschi', 'henrique@demo.com', '1991-06-25', 'masculino', 'aPos', 81, 'Ituporanga', true],
  ['d11', 'Isabela Wagner', 'isabela@demo.com', '1997-03-17', 'feminino', 'oPos', 64, 'Taió', true],
  ['d12', 'João Vitor Zimmermann', 'joao@demo.com', '2003-08-09', 'masculino', 'aPos', 75, 'Rio do Sul', true],
  ['d13', 'Karina Stolf', 'karina@demo.com', '1990-01-22', 'feminino', 'oNeg', 59, 'Ibirama', true],
  ['d14', 'Leonardo Dalmarco', 'leonardo@demo.com', '1987-09-30', 'masculino', 'bPos', 88, 'Rio do Sul', false],
  ['d15', 'Marcos Tomio', 'marcos@demo.com', '1995-05-05', 'masculino', 'abNeg', 70, 'Presidente Getúlio', true],
  ['d16', 'Natália Bona', 'natalia@demo.com', '2000-11-11', 'feminino', 'aNeg', 57, 'Rio do Sul', true],
];

/** Monta todos os documentos, já com os uids reais das contas. */
export function montarDocumentos(uids) {
  const inst = {};
  const docs = [];
  const add = (colecao, id, dados) => docs.push([colecao, id, { ...dados, id }]);

  for (const i of INSTITUICOES) {
    const id = uids[i.email];
    inst[i.chave] = { id, nome: i.nome };
    add('instituicoes', id, {
      nome: i.nome, tipo: i.tipo, cidade: i.cidade, horario: i.horario,
      lat: i.lat, lng: i.lng, email: i.email,
      estoque: Object.fromEntries(TIPOS.map((t) => [t, i.excecoes[t] ?? 'estavel'])),
    });
  }

  const doador = {};
  for (const [chave, nome, email, nasc, sexo, tipo, peso, cidade, notif] of DOADORES) {
    const id = uids[email];
    doador[chave] = { id, tipo, notif };
    const [a, m, d] = nasc.split('-').map(Number);
    add('doadores', id, {
      nome, email, dataNascimento: iso(new Date(a, m - 1, d)), sexo, tipo, peso,
      telefone: '(47) 99999-0000', cidade, endereco: 'Endereço de exemplo, 100 - Centro',
      notificacoes: notif, termosAceitosEm: iso(dia(-200)), versaoTermos: '1.0',
      criadoEm: iso(dia(-200)),
    });
  }

  // Histórico de doações: [doador, dias atrás, hora, instituição (ou null = informada)]
  const historico = [
    ['d1', -40, 9, 'i2'], ['d1', -160, 10, 'i1'], ['d1', -300, 8, null],
    ['d2', -120, 14, 'i3'],
    ['d3', -95, 10, 'i2'],
    ['d4', -200, 9, 'i2'],
    ['d6', -75, 8, 'i1'], ['d6', -190, 9, 'i1'],
    ['d8', -70, 11, 'i1'],
    ['d9', -130, 15, 'i3'],
    ['d10', -65, 9, 'i4'],
    ['d11', -150, 10, 'i5'],
    ['d12', -30, 9, 'i5'],
    ['d13', -110, 14, 'i2'], ['d13', -230, 9, 'i2'],
    ['d15', -85, 10, 'i3'],
  ];
  const datas = {};
  historico.forEach(([d, delta, hora, i], n) => {
    const data = diaUtil(delta, hora);
    datas[`${d}${delta}`] = data;
    add('doacoes', `dc${n + 1}`, {
      doadorId: doador[d].id, data: iso(data),
      local: i ? inst[i].nome : 'Coleta Itinerante UNIDAVI',
      instituicaoId: i ? inst[i].id : null, informadaPeloDoador: !i,
    });
  });

  // Agendamentos: [doador, instituição, data, status, criado (dias)]
  const agendas = [
    ['d1', 'i2', datas['d1-40'], 'realizado', -45],
    ['d2', 'i2', diaUtil(2, 9), 'agendado', -1],
    ['d3', 'i2', diaUtil(1, 10, 30), 'confirmado', -3],
    ['d5', 'i2', diaUtil(3, 14), 'agendado', 0],
    ['d9', 'i2', diaUtil(4, 8, 30), 'agendado', 0],
    ['d11', 'i2', diaUtil(1, 13, 30), 'confirmado', -2],
    ['d4', 'i2', diaUtil(-3, 9), 'faltou', -10],
    ['d6', 'i1', diaUtil(2, 8, 30), 'agendado', -2],
    ['d7', 'i1', diaUtil(5, 10), 'agendado', -1],
    ['d16', 'i3', diaUtil(3, 9, 30), 'confirmado', -4],
    ['d14', 'i4', diaUtil(6, 15), 'agendado', 0],
  ];
  agendas.forEach(([d, i, data, status, criado], n) => {
    add('agendamentos', `ag${n + 1}`, {
      doadorId: doador[d].id, instituicaoId: inst[i].id, dataHora: iso(data),
      status, criadoEm: iso(dia(criado)),
    });
  });

  // Alertas e as notificações enviadas aos doadores compatíveis.
  const agora = new Date();
  const alertas = [
    {
      id: 'al1', inst: 'i1', tipo: 'campanha', titulo: 'Estoque crítico de O- e O+',
      mensagem: 'Nossos estoques de sangue tipo O estão muito baixos. Agende sua doação!',
      tipos: ['oNeg', 'oPos'], criado: new Date(agora.getTime() - 26 * 3600e3), ativo: true,
    },
    {
      id: 'al2', inst: 'i2', tipo: 'urgencia', titulo: 'Urgência: paciente B- na UTI',
      mensagem: 'Precisamos de doadores B- e O- ainda esta semana.',
      tipos: ['bNeg', 'oNeg'], criado: new Date(agora.getTime() - 5 * 3600e3), ativo: true,
    },
    {
      id: 'al3', inst: 'i5', tipo: 'campanha', titulo: 'Campanha Doe Vida UNIDAVI',
      mensagem: 'Coleta itinerante no campus no sábado. Traga um documento com foto!',
      tipos: TIPOS, criado: new Date(agora.getTime() - 20 * 86400e3), ativo: false,
    },
  ];
  for (const a of alertas) {
    const alvo = Object.entries(doador).filter(([, d]) => a.tipos.includes(d.tipo) && d.notif);
    add('alertas', a.id, {
      instituicaoId: inst[a.inst].id, tipo: a.tipo, titulo: a.titulo, mensagem: a.mensagem,
      tiposNecessarios: a.tipos, criadoEm: iso(a.criado), ativo: a.ativo, notificados: alvo.length,
    });
    for (const [chave, d] of alvo) {
      add('notificacoes', `n_${a.id}_${chave}`, {
        doadorId: d.id, alertaId: a.id, titulo: a.titulo,
        corpo: `${inst[a.inst].nome}: ${a.mensagem}`, criadaEm: iso(a.criado),
        lida: !a.ativo,
      });
    }
  }
  return docs;
}

/**
 * Cria (ou reaproveita) as contas no Firebase Auth, apaga os dados antigos e
 * grava os dados de demonstração. `fb` traz as funções do SDK modular.
 */
export async function semear(fb, config, senhaAdmin, log = console.log) {
  const app = fb.initializeApp(config, `seed-${Date.now()}`);
  const auth = fb.getAuth(app);
  const db = fb.getFirestore(app);

  async function conta(email, senha) {
    try {
      const c = await fb.createUserWithEmailAndPassword(auth, email, senha);
      return c.user.uid;
    } catch (e) {
      if (e.code !== 'auth/email-already-in-use') throw e;
      const c = await fb.signInWithEmailAndPassword(auth, email, senha);
      return c.user.uid;
    } finally {
      await fb.signOut(auth);
    }
  }

  const uids = {};
  uids[EMAIL_ADMIN] = await conta(EMAIL_ADMIN, senhaAdmin);
  for (const i of INSTITUICOES) uids[i.email] = await conta(i.email, SENHA_DEMO);
  for (const d of DOADORES) uids[d[2]] = await conta(d[2], SENHA_DEMO);
  log(`Contas prontas: ${Object.keys(uids).length}`);

  await fb.signInWithEmailAndPassword(auth, EMAIL_ADMIN, senhaAdmin);

  const colecoes = ['notificacoes', 'alertas', 'agendamentos', 'doacoes', 'doadores', 'instituicoes'];
  let apagados = 0;
  for (const c of colecoes) {
    const snap = await fb.getDocs(fb.collection(db, c));
    let lote = fb.writeBatch(db);
    let n = 0;
    for (const d of snap.docs) {
      lote.delete(d.ref);
      if (++n % 400 === 0) { await lote.commit(); lote = fb.writeBatch(db); }
    }
    await lote.commit();
    apagados += snap.size;
  }
  log(`Documentos antigos apagados: ${apagados}`);

  const docs = montarDocumentos(uids);
  for (let i = 0; i < docs.length; i += 400) {
    const lote = fb.writeBatch(db);
    for (const [c, id, dados] of docs.slice(i, i + 400)) lote.set(fb.doc(db, c, id), dados);
    await lote.commit();
  }
  const resumo = {};
  for (const [c] of docs) resumo[c] = (resumo[c] ?? 0) + 1;
  log(`Gravados: ${JSON.stringify(resumo)}`);

  await fb.signOut(auth);
  await fb.deleteApp(app);
  return resumo;
}
