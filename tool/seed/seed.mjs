// Popula o Firebase do DoaVida com os dados de demonstração.
//
// Uso (Node 18+):
//   cd tool/seed
//   npm install
//   SENHA_ADMIN='uma-senha-forte' node seed.mjs
//
// A conta admin@doavida.app é criada na primeira execução com a senha
// informada e só ela pode apagar/recriar os dados (ver firestore.rules).
// Rodar de novo volta tudo ao estado inicial de demonstração.

import { deleteApp, initializeApp } from 'firebase/app';
import {
  createUserWithEmailAndPassword, getAuth, signInWithEmailAndPassword, signOut,
} from 'firebase/auth';
import { collection, doc, getDocs, getFirestore, writeBatch } from 'firebase/firestore';

import { semear } from './dados_demo.mjs';

const config = {
  apiKey: 'AIzaSyA4XO6TisjpanfqWPT-jbSJD-Yb6XLzUOo',
  authDomain: 'doavida-b5ef1.firebaseapp.com',
  projectId: 'doavida-b5ef1',
  storageBucket: 'doavida-b5ef1.firebasestorage.app',
  messagingSenderId: '71385485787',
  appId: '1:71385485787:web:6bf86eff474a9291f717fe',
};

const senha = process.env.SENHA_ADMIN;
if (!senha || senha.length < 8) {
  console.error('Defina SENHA_ADMIN (mínimo 8 caracteres).');
  process.exit(1);
}

const fb = {
  initializeApp, deleteApp, getAuth, createUserWithEmailAndPassword,
  signInWithEmailAndPassword, signOut, getFirestore, collection, doc, getDocs, writeBatch,
};

await semear(fb, config, senha);
console.log('Pronto!');
process.exit(0);
