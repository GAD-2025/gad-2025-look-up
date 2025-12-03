const express = require("express");
const cors = require("cors");
const app = express();

app.use(cors());
app.use(express.json());

// 테스트용 API (GET)
app.get("/hello", (req, res) => {
  res.json({ message: "Hello from Node.js backend!" });
});

// 테스트용 API (POST)
app.post("/login", (req, res) => {
  const { id, password } = req.body;

  if (id === "test" && password === "1234") {
    res.json({ success: true, token: "abc123" });
  } else {
    res.json({ success: false, message: "로그인 실패" });
  }
});

app.listen(3000, () => {
  console.log("🚀 Server running on http://localhost:3000");
});
