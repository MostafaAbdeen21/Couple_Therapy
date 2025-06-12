const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");
const { defineSecret } = require("firebase-functions/params");
const openAiSecret = defineSecret("OPENAI_API_KEY");


// ✅ Function 1: Generate GPT reply for Daily Journal
exports.generateGptReply = onCall({ cors: true, secrets: [openAiSecret] }, async (request) => {
  const openai = new OpenAI({ apiKey: openAiSecret.value() });

  const uid = request.auth?.uid;
  const text = request.data.text;
  if (!uid || !text) throw new Error("Missing uid or text");

  const userRef = admin.firestore().collection("users").doc(uid);
  const journalRef = userRef.collection("journals");
  const summariesRef = userRef.collection("summaries");
  const today = new Date().toISOString().slice(0, 10);

  const summariesSnap = await summariesRef.orderBy("timestamp", "desc").limit(3).get();
  const summaryText = summariesSnap.docs.map((doc, i) => {
    const d = doc.data();
    return i === 0 ? `Yesterday: [Summary: ${d.coreTheme}]` : `Previous: [Summary: ${d.coreTheme}]`;
  }).join("\n");

  const profileSnap = await userRef.get();
  const therapistProfile = profileSnap.data().therapistProfile || {};

  const tone = therapistProfile.tone || "compassionate";
  const focus = therapistProfile.focus || "emotional reflection";
  const depth = therapistProfile.depth || "medium";
  const language = therapistProfile.language || "English";

  const prompt = [
    {
      role: "system",
      content: `You are a ${tone} relationship therapist. Focus on ${focus} with ${depth} depth. Respond in ${language}. Be emotionally supportive and empathetic.`,
    },
    {
      role: "user",
      content: `${summaryText}\n\nToday's entry: ${text}`,
    },
  ];

  const gptRes = await openai.chat.completions.create({
    model: "gpt-4-1106-preview",
    messages: prompt,
    temperature: 0.7,
    max_tokens: 400,
  });

  const reply = gptRes.choices[0].message.content;
  const usage = gptRes.usage;

  await journalRef.doc(today).set({
    message: text,
    gptReply: reply,
    tokenUsage: usage,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  // 🧠 Emotion Analysis (Improved Prompt)
  const emotionPrompt = [
    {
      role: "system",
      content: `
You are an emotion analysis assistant.
Your job is to analyze the user's journal entry and return a **strict valid JSON object**.

Only return a JSON object with **exactly** these 3 fields (all numbers from 0 to 10):
{
  "anger": number,
  "stress": number,
  "sadness": number
}

⚠️ No explanation, no extra text, no code block, no markdown, just the pure JSON only.
Example:
{"anger": 2, "stress": 5, "sadness": 1}
      `.trim(),
    },
    {
      role: "user",
      content: `Journal Entry: ${text}`,
    },
  ];

  let anger = 0, stress = 0, sadness = 0;

  try {
    const emotionRes = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: emotionPrompt,
      temperature: 0.3,
      max_tokens: 100,
    });

    const raw = emotionRes.choices[0].message.content;

    const match = raw.match(/\{[\s\S]*?\}/);
    if (match) {
      const parsed = JSON.parse(match[0]);
      anger = parsed.anger || 0;
      stress = parsed.stress || 0;
      sadness = parsed.sadness || 0;
    } else {
      console.warn("⚠️ GPT response did not contain valid JSON:", raw);
    }
  } catch (err) {
    console.error("Emotion parsing failed ❌", err);
  }

  await summariesRef.doc(today).set({
    coreTheme: `User expressed feelings of ${text.slice(0, 50)}...`,
    anger,
    stress,
    sadness,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  await userRef.set({
    journalCount: admin.firestore.FieldValue.increment(1),
  }, { merge: true });

  return { reply, usage, anger, stress, sadness };
});