const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");


// ✅ Function 3: Archive old journals
exports.archiveOldJournals = onSchedule("every 24 hours", async () => {
  const db = admin.firestore();
  const now = new Date();
  const cutoff = new Date(now.setDate(now.getDate() - 30)).toISOString();

  const usersSnap = await db.collection("users").get();

  for (const userDoc of usersSnap.docs) {
    const journalsRef = db.collection("users").doc(userDoc.id).collection("journals");
    const oldJournalsSnap = await journalsRef.where("timestamp", "<", new Date(cutoff)).get();

    for (const doc of oldJournalsSnap.docs) {
      const data = doc.data();
      const summary = `User expressed feelings of ${data.message?.slice(0, 50) || "..."}`;
      await db.collection("users").doc(userDoc.id).collection("summaries").doc(doc.id).set({
        coreTheme: summary,
        timestamp: data.timestamp,
      });
      await doc.ref.delete();
    }
  }

  return null;
});