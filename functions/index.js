const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const functions = require("firebase-functions"); // لازم تضيفها عشان HttpsError
const admin = require("firebase-admin");
const { OpenAI } = require("openai");




admin.initializeApp();

const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const webhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
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

  // 🧠 Emotion Analysis
  const summary = `User expressed feelings of ${text.slice(0, 50)}...`;

  const emotionPrompt = [
    {
      role: "system",
      content: "You are an emotion analysis assistant. Analyze the journal entry and return ONLY a valid JSON object with 3 scores from 0 to 10: anger, stress, sadness. No explanation, no text outside JSON.",
    },
    {
      role: "user",
      content: `Journal Entry: ${text}`,
    }
  ];

  let anger = 0, stress = 0, sadness = 0;

  try {
    const emotionRes = await openai.chat.completions.create({
      model: "gpt-4-1106-preview",
      messages: emotionPrompt,
      temperature: 0.3,
      max_tokens: 100,
    });

    const raw = emotionRes.choices[0].message.content;

    // استخراج JSON من الرد (حتى لو فيه نص خارجي)
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
    coreTheme: summary,
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

    // Fetch pair data to get userA and userB
    const pairDoc = await db.collection("pairs").doc(pairingId).get();
    const pairData = pairDoc.data();
    const userA = pairData?.userA;
    const userB = pairData?.userB;

    // Prepare GPT prompt
    const prompt = [
      {
        role: "system",
        content: `You are a relationship therapist facilitating a session between two partners. Use a balanced and validating tone to support healthy communication.`,
      },
    ];

    if (history.length > 0) {
      prompt.push(...history.slice(-6));
    } else {
      prompt.push({
        role: "user",
        content: `This is the first session between two partners. Start with a warm welcome and an open-ended question to help them begin.`,
      });
    }

    // Generate GPT response
    const gptRes = await openai.chat.completions.create({
      model: "gpt-4-1106-preview",
      messages: prompt,
      temperature: 0.7,
      max_tokens: 300,
    });

    const reply = gptRes.choices[0].message.content;

    // ✅ Increment sessionCount for both users
    const updates = [];
    if (userA) {
      updates.push(db.collection("users").doc(userA).set({
        sessionCount: admin.firestore.FieldValue.increment(1)
      }, { merge: true }));
    }
    if (userB) {
      updates.push(db.collection("users").doc(userB).set({
        sessionCount: admin.firestore.FieldValue.increment(1)
      }, { merge: true }));
    }
    await Promise.all(updates);

    return { reply };
  } catch (error) {
    console.error("🔥 Error in gptTherapyReply:", error);
    throw new functions.https.HttpsError('internal', error.message || 'Unknown error');
  }
});


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

// ✅ Function 4: Weekly Advice
exports.sendWeeklyReflection = onSchedule(
  {
    schedule: "50 * * * *", // ← عدّلها حسب ما يناسبك لاحقًا
    secrets: [openAiSecret]
  },
  async () => {
    const openai = new OpenAI({ apiKey: openAiSecret.value() });
    const db = admin.firestore();

    const pairsSnap = await db.collection("pairs").get();

    for (const pairDoc of pairsSnap.docs) {
      const pairingId = pairDoc.id;
      const pairData = pairDoc.data();

      const userAId = pairData.userA;
      const userBId = pairData.userB;

      if (!userAId || !userBId) continue;

      // Fetch profiles
      const [userAProfileSnap, userBProfileSnap] = await Promise.all([
        db.collection("users").doc(userAId).get(),
        db.collection("users").doc(userBId).get()
      ]);

      const userAProfile = userAProfileSnap.data()?.profile || {};
      const userBProfile = userBProfileSnap.data()?.profile || {};

      const challenges = [
        ...(userAProfile.challengeAreas || []),
        ...(userBProfile.challengeAreas || [])
      ];

      const preferredLanguage = userAProfile.language || userBProfile.language || "English";
      const tone = userAProfile.tone || "gentle";

      const challengeSummary = challenges.length
        ? `The couple is currently working through challenges such as: ${[...new Set(challenges)].join(", ")}.`
        : "The couple is exploring their relationship with openness and curiosity.";

      const prompt = [
        {
          role: "system",
          content: `You are an AI relationship therapist. Write a weekly reflection for a couple in a ${tone} tone, based on their emotional challenges. Language: ${preferredLanguage}. Speak directly to the couple. DO NOT use placeholders like [Couple's Names] or [Your Name]. Do not use greetings or signatures. Just start the message as if continuing an ongoing conversation.`,
        },
        {
          role: "user",
          content: `${challengeSummary} Provide a thoughtful reflection or emotional support message or an exercise for the upcoming week.`,
        },
      ];

      try {
        const gptRes = await openai.chat.completions.create({
          model: "gpt-4-1106-preview",
          messages: prompt,
          temperature: 0.7,
          max_tokens: 350,
        });

        const message = gptRes.choices[0].message.content;

        await db.collection("pairs").doc(pairingId).collection("groupChat").add({
          message,
          sender: "gpt",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (err) {
        console.error(`Failed to send reflection to pair ${pairingId}`, err);
      }
    }

    return null;
  }
);

exports.createCheckoutSession = onCall({ cors: true, secrets: [stripeSecret] }, async (request) => {
  const stripe = require("stripe")(stripeSecret.value());
  const uid = request.auth?.uid;
  if (!uid) throw new Error("User not authenticated");

  const pairingId = request.data.pairingId;
  const plan = request.data.plan;

  const prices = {
    monthly: "price_PLACEHOLDER_MONTHLY",
    quarterly: "price_PLACEHOLDER_QUARTERLY",
    yearly: "price_PLACEHOLDER_YEARLY",
  };

  const priceId = prices[plan];
  if (!priceId) throw new Error("Invalid plan selected");

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ["card"],
    mode: "subscription",
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: "https://example.com/success",
    cancel_url: "https://example.com/cancel",
    metadata: { uid, pairingId, plan },
  });

  return { url: session.url };
});

exports.stripeWebhook = onRequest({ secrets: [stripeSecret, webhookSecret], cors: true, rawBody: true }, async (req, res) => {
  const stripe = require("stripe")(stripeSecret.value());
  const sig = req.headers["stripe-signature"];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret.value());
  } catch (err) {
    console.error("❌ Webhook verification failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    const pairingId = session.metadata?.pairingId;
    const plan = session.metadata?.plan;
    const type = session.metadata?.type;
    const quantity = parseInt(session.metadata?.quantity || "0");

    if (!pairingId) return res.status(400).send("Missing pairingId");

    const pairRef = admin.firestore().collection("pairs").doc(pairingId);
    try {
      if (plan) {
        await pairRef.set({ subscription: { status: "active", plan, start: admin.firestore.Timestamp.now() } }, { merge: true });
      } else if (type && quantity > 0) {
        const field = type === "journal" ? "extraJournals" : "extraSessions";
        await pairRef.set({ [field]: admin.firestore.FieldValue.increment(quantity) }, { merge: true });
      }
      return res.status(200).send("✅ Webhook handled");
    } catch (err) {
      console.error("❌ Firestore error:", err);
      return res.status(500).send("Firestore error");
    }
  }

  res.status(200).send("✅ Event received");
});

exports.buyAddOn = onCall({ cors: true, secrets: [stripeSecret] }, async (req) => {
  const stripe = require("stripe")(stripeSecret.value());
  const { pairingId, type, quantity } = req.data;
  if (!pairingId || !["journal", "session"].includes(type)) throw new functions.https.HttpsError("invalid-argument", "Invalid type or pairingId");

  const priceIds = {
    journal: {
      1: "price_1journal",
      5: "price_5journal",
      10: "price_10journal",
    },
    session: {
      1: "price_1session",
      3: "price_3session",
      5: "price_5session",
    },
  };

  const selectedPriceId = priceIds[type]?.[quantity];
  if (!selectedPriceId) throw new functions.https.HttpsError("invalid-argument", "Invalid quantity for selected type");

  const session = await stripe.checkout.sessions.create({
    mode: "payment",
    line_items: [{ price: selectedPriceId, quantity: 1 }],
    success_url: "https://your-app.com/addon-success",
    cancel_url: "https://your-app.com/cancel",
    metadata: { pairingId, type, quantity },
  });

  return { url: session.url };
});