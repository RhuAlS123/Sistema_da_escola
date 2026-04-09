/**
 * Cria (ou reutiliza) os 3 utilizadores do escopo e grava `usuarios/{uid}` no Firestore.
 *
 * Variáveis de ambiente obrigatórias:
 *   GOOGLE_APPLICATION_CREDENTIALS — caminho para o JSON da conta de serviço
 *   SEED_PASS_COLAB1, SEED_PASS_COLAB2, SEED_PASS_ADMIN — senhas em texto plano (só no terminal)
 *
 * Uso: ver app_escola/SETUP_USUARIOS.md — Opção B
 */
import { readFileSync, existsSync } from 'fs';
import { dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));

const USERS = [
  {
    email: 'colab1@escola.com',
    nome: 'Colaborador 1',
    role: 'colab',
    envPass: 'SEED_PASS_COLAB1',
  },
  {
    email: 'colab2@escola.com',
    nome: 'Colaborador 2',
    role: 'colab',
    envPass: 'SEED_PASS_COLAB2',
  },
  {
    email: 'admin@escola.com',
    nome: 'Administrador',
    role: 'admin',
    envPass: 'SEED_PASS_ADMIN',
  },
];

function loadCredential() {
  const pathFromEnv = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (pathFromEnv && existsSync(pathFromEnv)) {
    const raw = readFileSync(pathFromEnv, 'utf8');
    return JSON.parse(raw);
  }
  const fallback = resolve(__dirname, 'serviceAccount.json');
  if (existsSync(fallback)) {
    const raw = readFileSync(fallback, 'utf8');
    return JSON.parse(raw);
  }
  console.error(
    'Defina GOOGLE_APPLICATION_CREDENTIALS com o caminho para o JSON da conta de serviço,\n' +
      'ou coloque serviceAccount.json nesta pasta (não versionar). Ver SETUP_USUARIOS.md',
  );
  process.exit(1);
}

function ensureApp() {
  if (getApps().length > 0) return;
  const sa = loadCredential();
  initializeApp({ credential: cert(sa) });
}

async function upsertUser(auth, { email, password, nome, role }) {
  let uid;
  try {
    const existing = await auth.getUserByEmail(email);
    uid = existing.uid;
    await auth.updateUser(uid, { password, displayName: nome });
    console.log(`Auth: atualizado ${email} (uid=${uid})`);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      const created = await auth.createUser({
        email,
        password,
        displayName: nome,
        emailVerified: false,
      });
      uid = created.uid;
      console.log(`Auth: criado ${email} (uid=${uid})`);
    } else {
      throw e;
    }
  }

  const db = getFirestore();
  await db.collection('usuarios').doc(uid).set(
    {
      nome,
      role,
    },
    { merge: true },
  );
  console.log(`Firestore: usuarios/${uid} → nome="${nome}", role="${role}"`);
}

async function main() {
  ensureApp();
  const auth = getAuth();

  for (const u of USERS) {
    const password = process.env[u.envPass];
    if (!password || !String(password).trim()) {
      console.error(
        `Defina a variável de ambiente ${u.envPass} com a senha para ${u.email}.`,
      );
      process.exit(1);
    }
    await upsertUser(auth, {
      email: u.email,
      password: String(password),
      nome: u.nome,
      role: u.role,
    });
  }

  console.log('\nConcluído. Pode testar o login no app com os três e-mails.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
