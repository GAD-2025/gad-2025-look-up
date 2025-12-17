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

// New route for creating a post
app.post('/api/posts', async (req, res) => {
  const { imagePath, caption, isVideo, userId } = req.body;

  if (!imagePath || !userId) {
    return res.status(400).json({ message: 'imagePath and userId are required.' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO posts (image_path, caption, is_video, user_id) VALUES (?, ?, ?, ?)',
      [imagePath, caption, isVideo || false, userId]
    );
    res.status(201).json({ message: 'Post created successfully', postId: result.insertId });
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({ message: 'Server error while creating post.' });
  }
});

// New route to get all posts
app.get('/api/posts', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM posts ORDER BY created_at DESC');
    res.json(rows);
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ message: 'Server error while fetching posts.' });
  }
});

module.exports = app;
