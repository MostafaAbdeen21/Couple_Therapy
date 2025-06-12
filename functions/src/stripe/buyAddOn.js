const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const stripeSecret = defineSecret("STRIPE_SECRET_KEY");

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