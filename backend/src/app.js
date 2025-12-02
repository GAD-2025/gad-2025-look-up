const express = require('express');
const app = express();
const db = require('./config/db'); // Import the database connection

// Middleware
app.use(express.json()); // for parsing application/json
app.use(express.urlencoded({ extended: true })); // for parsing application/x-www-form-urlencoded

// Routes
app.get('/', (req, res) => {
  res.send('Backend is running!');
});

// New route for ID duplication check
app.post('/check-id-duplication', async (req, res) => {
  const { id } = req.body;
  console.log('Received ID for duplication check:', id);

  if (!id) {
    console.log('ID is missing from request.');
    return res.status(400).json({ message: 'ID is required.' });
  }

  try {
    const [rows] = await db.execute('SELECT id FROM users WHERE id = ?', [id]);
    console.log('Database query result (rows):', rows);
    const isDuplicated = rows.length > 0;
    console.log('Is ID duplicated:', isDuplicated);
    res.json({ isDuplicated });
  } catch (error) {
    console.error('Error checking ID duplication:', error);
    res.status(500).json({ message: 'Server error during ID duplication check.' });
  }
});

module.exports = app;
