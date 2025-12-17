const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const app = express();
const db = require('./config/db'); // Import the database connection

// --- Multer and File Upload Setup ---

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Multer storage configuration
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });

// --- Middleware ---
app.use(express.json()); // for parsing application/json
app.use(express.urlencoded({ extended: true })); // for parsing application/x-www-form-urlencoded

// Serve uploaded files statically
app.use('/uploads', express.static(uploadsDir));


// --- Routes ---
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

// --- SSO Authentication Routes ---

// Check if a user is registered with a Kakao ID
app.post('/auth/kakao', async (req, res) => {
  const { kakaoId } = req.body;
  if (!kakaoId) {
    return res.status(400).json({ message: 'Kakao ID is required.' });
  }

  try {
    const [rows] = await db.execute('SELECT id, nickname FROM users WHERE kakao_id = ?', [kakaoId]);
    if (rows.length > 0) {
      res.json({ isRegistered: true, user: rows[0] });
    } else {
      res.json({ isRegistered: false });
    }
  } catch (error) {
    console.error('Error checking Kakao auth:', error);
    res.status(500).json({ message: 'Server error during Kakao authentication.' });
  }
});

// Sign up a new user
app.post('/signup', async (req, res) => {
  const { id, nickname, kakaoId } = req.body;
  if (!id || !nickname || !kakaoId) {
    return res.status(400).json({ message: 'ID, nickname, and Kakao ID are required.' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO users (id, nickname, kakao_id) VALUES (?, ?, ?)',
      [id, nickname, kakaoId]
    );
    res.status(201).json({
      message: 'User created successfully',
      user: { id, nickname }
    });
  } catch (error) {
    // Handle potential duplicate entry for 'id' or 'kakao_id'
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'User with this ID or Kakao ID already exists.' });
    }
    console.error('Error creating user:', error);
    res.status(500).json({ message: 'Server error while creating user.' });
  }
});

// --- Feed and Post Routes ---

// Create a new feed
app.post('/api/feeds', async (req, res) => {
  const { emoji, location } = req.body;
  if (!emoji || !location) {
    return res.status(400).json({ message: 'Emoji and location are required.' });
  }

  // Set expiration time to 3 minutes from now
  const expiresAt = new Date(Date.now() + 3 * 60 * 1000);

  try {
    const [result] = await db.execute(
      'INSERT INTO feeds (emoji, location, expires_at) VALUES (?, ?, ?)',
      [emoji, location, expiresAt]
    );
    res.status(201).json({ feedId: result.insertId });
  } catch (error) {
    console.error('Error creating feed:', error);
    res.status(500).json({ message: 'Server error while creating feed.' });
  }
});


// Modified route for creating a post with image upload
app.post('/api/posts', upload.single('image'), async (req, res) => {
  // 'feedId' is now required
  const { caption, isVideo, userId, feedId } = req.body;
  
  if (!req.file || !userId || !feedId) {
    return res.status(400).json({ message: 'Image file, userId, and feedId are required.' });
  }

  const imagePath = `/uploads/${req.file.filename}`;

  try {
    const [result] = await db.execute(
      // Added feed_id to the insert statement
      'INSERT INTO posts (image_path, caption, is_video, user_id, feed_id) VALUES (?, ?, ?, ?, ?)',
      [imagePath, caption, isVideo === 'true' || false, userId, feedId]
    );
    res.status(201).json({ message: 'Post created successfully', postId: result.insertId, imagePath: imagePath });
  } catch (error) {
    console.error('Error creating post:', error);
    // If there's an error, try to delete the uploaded file
    fs.unlink(req.file.path, (err) => {
      if (err) console.error("Error deleting uploaded file after DB error:", err);
    });
    res.status(500).json({ message: 'Server error while creating post.' });
  }
});

// New route to get posts for a specific feed
app.get('/api/feeds/:feedId/posts', async (req, res) => {
  const { feedId } = req.params;
  if (!feedId) {
    return res.status(400).json({ message: 'Feed ID is required.' });
  }

  try {
    const [rows] = await db.execute(`
      SELECT
        p.image_path,
        p.caption,
        p.is_video,
        p.user_id,
        p.created_at,
        u.nickname
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE p.feed_id = ?
      ORDER BY p.created_at DESC
    `, [feedId]);
    res.json(rows);
  } catch (error) {
    console.error(`Error fetching posts for feed ${feedId}:`, error);
    res.status(500).json({ message: 'Server error while fetching posts.' });
  }
});


/*
// This route is deprecated in favor of /api/feeds/:feedId/posts
// to ensure posts are fetched for a specific feed instance.
// Kept for reference, can be removed later.
app.get('/api/posts', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM posts ORDER BY created_at DESC');
    res.json(rows);
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ message: 'Server error while fetching posts.' });
  }
});
*/

module.exports = app;
