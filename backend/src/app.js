const express = require('express');
const app = express();

// Middleware
app.use(express.json()); // for parsing application/json
app.use(express.urlencoded({ extended: true })); // for parsing application/x-www-form-urlencoded

// Routes
app.get('/', (req, res) => {
  res.send('Backend is running!');
});

module.exports = app;
