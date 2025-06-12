const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { defineSecret } = require("firebase-functions/params");
const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const webhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

exports.stripeWebhook = onRequest({
 secrets: [stripeSecret, webhookSecret], cors: true, rawBody: true }, async (req, res) => {
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