const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const stripeSecret = defineSecret("STRIPE_SECRET_KEY");

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