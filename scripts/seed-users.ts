/**
 * Cria/atualiza utilizadores na coleção `users`.
 * Requer regras Firestore que permitam escrita (ex.: modo de teste) ou corre com rede ok.
 * Se der permission-denied, cria os mesmos campos manualmente na consola Firestore.
 */
import 'dotenv/config';
import {initializeApp} from 'firebase/app';
import {
  collection,
  doc,
  getDocs,
  getFirestore,
  query,
  setDoc,
  where,
} from 'firebase/firestore';

const firebaseConfig = {
  apiKey: process.env.VITE_FIREBASE_API_KEY,
  authDomain: process.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.VITE_FIREBASE_APP_ID,
};

const SEED_USERS = [
  {username: 'Colaborador 1', password: '12342020', role: 'Colaborador' as const},
  {username: 'Colaborador 2', password: '12343030', role: 'Colaborador' as const},
  {username: 'Administrador', password: 'adm102030', role: 'Administrador' as const},
];

function requireEnv(): void {
  const missing = Object.entries(firebaseConfig)
    .filter(([, v]) => !v)
    .map(([k]) => k);
  if (missing.length) {
    throw new Error(
      `Variáveis em falta no .env: ${missing.join(', ')}. Corre na raiz do projeto.`,
    );
  }
}

async function main() {
  requireEnv();
  const app = initializeApp(firebaseConfig);
  const db = getFirestore(app);

  for (const u of SEED_USERS) {
    const q = query(collection(db, 'users'), where('username', '==', u.username));
    const snap = await getDocs(q);
    const payload = {
      username: u.username,
      password: u.password,
      role: u.role,
      isActive: true,
    };

    if (snap.empty) {
      const ref = doc(collection(db, 'users'));
      await setDoc(ref, payload);
      console.log(`Criado: ${u.username} (${u.role}) id=${ref.id}`);
    } else {
      const id = snap.docs[0].id;
      await setDoc(doc(db, 'users', id), payload, {merge: true});
      console.log(`Atualizado: ${u.username} (${u.role}) id=${id}`);
    }
  }

  console.log('Concluído.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
