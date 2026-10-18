# Upgrading Shareloop to the Blaze plan (optional, later)

Not needed for Phase 1. Use this only if the team later wants true push
notifications (that wake a closed app) or Firebase Storage instead of Cloudinary.

1. Firebase console → **Upgrade** → Blaze, and set a USD 5 budget alert.
2. *Build → Storage → Get started* → Production mode → `asia-south1`.
3. Move these back to the project root:
   ```bash
   mv blaze-upgrade/functions blaze-upgrade/storage.rules .
   ```
4. Add to `firebase.json`:
   ```json
   "storage": { "rules": "storage.rules" },
   "functions": [{ "source": "functions", "codebase": "default",
                   "ignore": ["node_modules", ".git", "*.local"] }]
   ```
5. In `firestore.rules`, change notifications `allow create` to `if false` (the functions write them instead),
   and remove the app-side counter updates from `request_service.dart`.
6. App saves its FCM token to `users/{uid}.fcmTokens` (array) after login.
7. Deploy:
   ```bash
   cd functions && npm install && cd ..
   firebase deploy --only firestore:rules,storage,functions
   ```
