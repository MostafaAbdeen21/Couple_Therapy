const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");
const { defineSecret } = require("firebase-functions/params");
const openAiSecret = defineSecret("OPENAI_API_KEY");

// ✅ Function 2: GPT reply for shared therapy chat
exports.gptTherapyReply = onCall({ cors: true, secrets: [openAiSecret] }, async (request) => {
  try {
    const openai = new OpenAI({ apiKey: openAiSecret.value() });
    const db = admin.firestore();

    const pairingId = request.data.pairingId;
    const history = request.data.history || [];

    if (!pairingId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing pairingId');
    }

    const pairRef = db.collection("pairs").doc(pairingId);
    const pairDoc = await pairRef.get();
    const pairData = pairDoc.data();

    const userA = pairData?.userA;
    const userB = pairData?.userB;
    const tokenLimit = pairData?.tokenLimit || 3000;
    const tokenUsedThisWeek = pairData?.tokenUsedThisWeek || 0;
    const lastSessionTimestamp = pairData?.lastSessionTimestamp?.toDate?.();

    const now = new Date();
    const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (now.getDay() || 7) + 1);
    const shouldUpdateLastSession = !lastSessionTimestamp || lastSessionTimestamp < startOfWeek;

    // ✅ احضار آخر 2–3 journal entries + summaries
    const allUserIds = [userA, userB].filter(Boolean);
    const journalSnippets = [];

    for (const uid of allUserIds) {
      const journalSnap = await db.collection("users").doc(uid).collection("journals")
        .orderBy("timestamp", "desc").limit(3).get();

      const summarySnap = await db.collection("users").doc(uid).collection("summaries")
        .orderBy("timestamp", "desc").limit(3).get();

      const summaries = summarySnap.docs.map(doc => {
        const d = doc.data();
        return `Summary: ${d.coreTheme}. Emotions - anger: ${d.anger}/10, stress: ${d.stress}/10, sadness: ${d.sadness}/10.`;
      });

      journalSnap.docs.forEach((doc, i) => {
        const text = doc.data().message;
        const sumText = summaries[i] || '';
        journalSnippets.push(`Journal ${i + 1} by ${uid}: ${text}\n${sumText}`);
      });
    }

    // ✅ إعداد prompt
    const prompt = [
      {
        role: "system",
        content: `You are a relationship therapist facilitating a session between two partners. Use a balanced, validating tone to support healthy communication.`,
      },
      {
        role: "user",
        content: `Here is recent journal history from both users:\n\n${journalSnippets.join('\n\n')}`,
      },
    ];

    if (history.length > 0) {
      prompt.push(...history.slice(-6));
    } else {
      prompt.push({
        role: "user",
        content: `This is the first session. Start with a warm welcome and an open-ended question to begin the conversation.`,
      });
    }

    // ✅ استدعاء GPT
    const gptRes = await openai.chat.completions.create({
      model: "gpt-4-1106-preview",
      messages: prompt,
      temperature: 0.7,
      max_tokens: 350,
    });

    const reply = gptRes.choices[0].message.content;
    const tokenUsed = gptRes.usage.total_tokens;

    // ✅ تحديث البيانات
    const updateData = {
      tokenUsedThisWeek: admin.firestore.FieldValue.increment(tokenUsed),
    };

    if (shouldUpdateLastSession) {
      updateData.lastSessionTimestamp = admin.firestore.FieldValue.serverTimestamp();
    }

    await pairRef.set(updateData, { merge: true });

    // ✅ التحقق من تجاوز الحد
    if (tokenUsedThisWeek + tokenUsed >= tokenLimit) {
      await pairRef.set({ sessionLimitReached: true }, { merge: true });
    }

    return { reply, tokenUsed };
  } catch (error) {
    console.error("🔥 Error in gptTherapyReply:", error);
    throw new functions.https.HttpsError('internal', error.message || 'Unknown error');
  }
});