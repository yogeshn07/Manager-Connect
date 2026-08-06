# Firebase Production Setup

## 1. Project Creation

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click "Add project"
3. **Name:** `manager-connect-prod`
4. **Analytics:** Enable (optional)
5. Wait for project creation

## 2. Web Configuration

### Enable Cloud Messaging

1. Project Settings → Cloud Messaging
2. Verify "Cloud Messaging API (V1)" is enabled
3. If not, click "Manage API in Google Cloud Console" → Enable

### Get Web App Config

1. Project Settings → General → Your apps → Add app → Web
2. **App nickname:** `manager-connect-web`
3. Copy the config values:

```
apiKey: "AIza..."
authDomain: "manager-connect-prod.firebaseapp.com"
projectId: "manager-connect-prod"
storageBucket: "manager-connect-prod.appspot.com"
messagingSenderId: "123456789"
appId: "1:123456789:web:abc123"
```

### Build Command

```bash
flutter build web --no-web-resources-cdn \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=FIREBASE_API_KEY=AIza... \
  --dart-define=FIREBASE_AUTH_DOMAIN=manager-connect-prod.firebaseapp.com \
  --dart-define=FIREBASE_PROJECT_ID=manager-connect-prod \
  --dart-define=FIREBASE_STORAGE_BUCKET=manager-connect-prod.appspot.com \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 \
  --dart-define=FIREBASE_APP_ID=1:123456789:web:abc123
```

## 3. Android Configuration (Future)

1. Project Settings → Add app → Android
2. **Package name:** `com.managerconnect.app`
3. Download `google-services.json`
4. Place in `frontend/android/app/google-services.json`

## 4. iOS Configuration (Future)

1. Project Settings → Add app → iOS
2. **Bundle ID:** `com.managerconnect.app`
3. Download `GoogleService-Info.plist`
4. Place in `frontend/ios/Runner/GoogleService-Info.plist`

## 5. FCM Server Key for Edge Functions

### Get Server Key

1. Project Settings → Cloud Messaging → Cloud Messaging API (V1)
2. Generate a new server key or use the existing one

### Deploy to Supabase

```bash
supabase secrets set FCM_SERVER_KEY=<server-key> --project-ref <ref>
```

The `send-notification` Edge Function reads this from `Deno.env.get('FCM_SERVER_KEY')`.

## 6. Service Worker (Web Push)

Create `frontend/web/firebase-messaging-sw.js`:

```javascript
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "...",
  projectId: "manager-connect-prod",
  messagingSenderId: "123456789",
  appId: "..."
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'Manager Connect';
  const options = { body: payload.notification?.body || '' };
  return self.registration.showNotification(title, options);
});
```

Note: Service worker config values must be hardcoded (no dart-define in JS). Use the same values as the build command.

## 7. Secret Management

| Secret | Where Stored | Who Needs Access |
|--------|-------------|-----------------|
| Firebase API Key | dart-define in CI/CD | Build pipeline |
| Firebase App ID | dart-define in CI/CD | Build pipeline |
| FCM Server Key | Supabase secrets | Edge Functions |
| google-services.json | Git (Android only) | Android builds |
| GoogleService-Info.plist | Git (iOS only) | iOS builds |

**Never commit FCM Server Key to git.** It grants push send capability.

## 8. Verification

After setup:

1. Build web with all dart-defines
2. Open app in browser
3. Check console: "Firebase initialized" should appear
4. Check: `FirebaseMessaging.instance.getToken()` returns a token
5. Verify token is stored in `profiles.push_token`
6. Send test notification via `send-notification` EF
7. Verify browser notification appears
