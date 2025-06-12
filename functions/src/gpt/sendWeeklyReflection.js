const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");
const { defineSecret } = require("firebase-functions/params");
const openAiSecret = defineSecret("OPENAI_API_KEY");

// ✅ Function 4: Weekly Advice
exports.sendWeeklyReflection = onSchedule(
  {
    schedule: "* * * * *", // ← عدّلها حسب ما يناسبك لاحقًا
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
