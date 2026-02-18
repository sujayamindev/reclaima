# Firebase Service Account Configuration

## ⚠️ IMPORTANT: This is a placeholder file

**DO NOT** commit your actual Firebase service account JSON to version control!

---

## 📝 How to Get Your Firebase Service Account

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create a new one)
3. Click the **gear icon** → **Project Settings**
4. Navigate to the **Service Accounts** tab
5. Click **Generate new private key**
6. Save the downloaded JSON file as `firebase-service-account.json` in this directory

---

## 📂 Expected File Structure

Your `firebase-service-account.json` should look like this:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

---

## 🔒 Security Notes

- ✅ This file is in `.gitignore` (will NOT be committed)
- ✅ Contains sensitive credentials - keep it secret!
- ✅ Never share this file publicly
- ✅ Rotate keys if accidentally exposed

---

## 🚀 Quick Setup

```bash
# After downloading from Firebase Console:
# 1. Rename the downloaded file to: firebase-service-account.json
# 2. Place it in: backend/firebase-service-account.json
# 3. Verify path in .env: FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

---

## ✅ Verify Setup

```bash
# Check if file exists
ls -la backend/firebase-service-account.json

# Test Firebase connection
# Run the backend and check logs for:
# "Firebase Admin SDK initialized successfully"
```

---

**Need Help?** See [QUICKSTART.md](../QUICKSTART.md) for complete setup instructions.
