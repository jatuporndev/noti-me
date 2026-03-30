import { initializeApp, getApps, cert } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

function initFirebase() {
  if (getApps().length > 0) return;

  const credJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (credJson) {
    initializeApp({ credential: cert(JSON.parse(credJson)) });
    return;
  }

  // Fall back to ADC (works on GCP / local gcloud auth).
  initializeApp();
}

initFirebase();

export const db = getFirestore();
export const messaging = getMessaging();
