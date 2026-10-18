/**
 * Seeds the `categories` collection.
 *
 * 1. Firebase console → Project settings → Service accounts → Generate new private key
 * 2. Save it as scripts/serviceAccountKey.json  (NEVER commit it — it's in .gitignore)
 * 3. cd scripts && npm install
 * 4. node seed_categories.js   (run from inside scripts/)
 *
 * Emulator: FIRESTORE_EMULATOR_HOST=localhost:8080 node seed_categories.js
 */
const admin = require("firebase-admin");

if (process.env.FIRESTORE_EMULATOR_HOST) {
  admin.initializeApp({ projectId: "shareloop-c2157" });
} else {
  admin.initializeApp({
    credential: admin.credential.cert(require("./serviceAccountKey.json")),
  });
}
const db = admin.firestore();

const categories = [
  { id: "clothing",    icon: "checkroom",      en: "Clothing",        si: "ඇඳුම්",             ta: "ஆடைகள்" },
  { id: "books",       icon: "menu_book",      en: "Books & Stationery", si: "පොත් සහ ලිපි ද්‍රව්‍ය", ta: "புத்தகங்கள் & எழுதுபொருள்" },
  { id: "electronics", icon: "devices",        en: "Electronics",     si: "ඉලෙක්ට්‍රොනික",       ta: "மின்னணு சாதனங்கள்" },
  { id: "furniture",   icon: "chair",          en: "Furniture",       si: "ගෘහ භාණ්ඩ",          ta: "தளபாடங்கள்" },
  { id: "kitchen",     icon: "kitchen",        en: "Kitchen & Home",  si: "කුස්සිය සහ නිවස",      ta: "சமையலறை & வீடு" },
  { id: "toys",        icon: "toys",           en: "Toys & Kids",     si: "සෙල්ලම් බඩු",         ta: "பொம்மைகள்" },
  { id: "sports",      icon: "sports_soccer",  en: "Sports",          si: "ක්‍රීඩා",              ta: "விளையாட்டு" },
  { id: "other",       icon: "category",       en: "Other",           si: "වෙනත්",              ta: "மற்றவை" },
];

(async () => {
  const batch = db.batch();
  categories.forEach((c, i) => {
    batch.set(db.collection("categories").doc(c.id), {
      name: { en: c.en, si: c.si, ta: c.ta },
      icon: c.icon,
      order: i + 1,
    });
  });
  await batch.commit();
  console.log(`Seeded ${categories.length} categories ✔`);
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
