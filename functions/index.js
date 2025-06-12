const admin = require("firebase-admin");
admin.initializeApp();

// مباشرة بدون استيراد من index.js داخلي
exports.generateGptReply = require("./src/gpt/generateGptReply");
exports.gptTherapyReply = require("./src/gpt/gptTherapyReply");
exports.sendWeeklyReflection = require("./src/gpt/sendWeeklyReflection");

exports.archiveOldJournals = require("./src/journals/archiveOldJournals");

exports.createCheckoutSession = require("./src/stripe/createCheckoutSession");
exports.buyAddOn = require("./src/stripe/buyAddOn");
exports.stripeWebhook = require("./src/stripe/stripeWebhook");
