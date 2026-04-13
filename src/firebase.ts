import { initializeApp, type FirebaseOptions } from 'firebase/app';
import { initializeFirestore } from 'firebase/firestore';

function getFirebaseConfig(): FirebaseOptions {
  const apiKey = import.meta.env.VITE_FIREBASE_API_KEY;
  const authDomain = import.meta.env.VITE_FIREBASE_AUTH_DOMAIN;
  const projectId = import.meta.env.VITE_FIREBASE_PROJECT_ID;
  const storageBucket = import.meta.env.VITE_FIREBASE_STORAGE_BUCKET;
  const messagingSenderId = import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID;
  const appId = import.meta.env.VITE_FIREBASE_APP_ID;
  const measurementId = import.meta.env.VITE_FIREBASE_MEASUREMENT_ID;

  if (!apiKey || !authDomain || !projectId || !storageBucket || !messagingSenderId || !appId) {
    throw new Error(
      'Firebase: cria um ficheiro .env na raiz com VITE_FIREBASE_* (modelo em .env.example).'
    );
  }

  const config: FirebaseOptions = {
    apiKey,
    authDomain,
    projectId,
    storageBucket,
    messagingSenderId,
    appId,
  };
  if (measurementId) {
    config.measurementId = measurementId;
  }
  return config;
}

const app = initializeApp(getFirebaseConfig());

export const db = initializeFirestore(app, {
  ignoreUndefinedProperties: true,
});
