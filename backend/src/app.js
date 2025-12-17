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

// Modified route for creating a post with image upload
app.post('/api/posts', upload.single('image'), async (req, res) => {
  const { caption, isVideo, userId } = req.body;
  
  // The 'image' file is now in req.file
  if (!req.file || !userId) {
    return res.status(400).json({ message: 'Image file and userId are required.' });
  }

  // Construct the image path to be saved in the DB
  // This path will be used by the client to fetch the image
  const imagePath = `/uploads/${req.file.filename}`;

  try {
    const [result] = await db.execute(
      'INSERT INTO posts (image_path, caption, is_video, user_id) VALUES (?, ?, ?, ?)',
      [imagePath, caption, isVideo === 'true' || false, userId]
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
