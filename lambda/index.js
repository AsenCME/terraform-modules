const random = require("random");

module.exports.handler = async () => {
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      ok: true,
      random_number: random.int(0, 100),
      message: "Works!",
    }),
  };
};
