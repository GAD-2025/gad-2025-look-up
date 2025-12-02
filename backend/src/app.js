const express = require('express');
const app = express();
const db = require('./config/db'); // Import the database connection
const axios = require('axios'); // Import axios for making HTTP requests
const jwt = require('jsonwebtoken'); // Import jsonwebtoken for JWT issuance

// Middleware
app.use(express.json()); // for parsing application/json
app.use(express.urlencoded({ extended: true })); // for parsing application/x-www-form-urlencoded

// Routes
app.get('/', (req, res) => {
  res.send('Backend is running!');
});

// New route for username duplication check
app.post('/check-username-duplication', async (req, res) => {
  const { username } = req.body;
  console.log('Received username for duplication check:', username);

  if (!username) {
    console.log('Username is missing from request.');
    return res.status(400).json({ message: 'Username is required.' });
  }

  try {
    const [rows] = await db.execute('SELECT username FROM users WHERE username = ?', [username]);
    console.log('Database query result (rows):', rows);
    const isDuplicated = rows.length > 0;
    console.log('Is username duplicated:', isDuplicated);
    res.json({ isDuplicated });
  } catch (error) {
    console.error('Error checking username duplication:', error);
    res.status(500).json({ message: 'Server error during username duplication check.' });
  }
});

// Kakao Login Callback Route
app.get('/auth/kakao/callback', async (req, res) => {
  const { code } = req.query;
  console.log('Received Kakao authorization code:', code);

  if (!code) {
    return res.status(400).json({ message: 'Authorization code is missing.' });
  }

  try {
    // 1. Get Kakao Access Token
    const tokenResponse = await axios.post('https://kauth.kakao.com/oauth/token', null, {
      params: {
        grant_type: 'authorization_code',
        client_id: process.env.KAKAO_CLIENT_ID,
        redirect_uri: process.env.KAKAO_REDIRECT_URI,
        code: code,
        client_secret: process.env.KAKAO_CLIENT_SECRET, // Required if you set it in Kakao Developers
      },
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });

    const { access_token } = tokenResponse.data;
    console.log('Kakao Access Token received.');

    // 2. Get Kakao User Info
    const userResponse = await axios.get('https://kapi.kakao.com/v2/user/me', {
      headers: {
        Authorization: `Bearer ${access_token}`,
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
      },
    });

    const kakaoUser = userResponse.data;
    const kakao_id = kakaoUser.id;
    const kakao_nickname = kakaoUser.kakao_account?.profile?.nickname || `KakaoUser_${kakao_id.toString().slice(-4)}`;
    console.log('Kakao User Info:', kakaoUser);
    console.log('Extracted kakao_id:', kakao_id);

    // 3. Search for user in our DB
    let [users] = await db.execute('SELECT * FROM users WHERE kakao_id = ?', [kakao_id]);
    let user = users[0];

    if (!user) {
      // User not found, register new user
      console.log('Kakao user not found in DB. Registering new user.');
      const generatedUsername = `kakao_${kakao_id}`; // Basic unique username
      const generatedNickname = kakao_nickname; // Use Kakao nickname or generated one

      // Check if generatedUsername is already taken (very unlikely for kakao_id based)
      let [existingUsername] = await db.execute('SELECT username FROM users WHERE username = ?', [generatedUsername]);
      if (existingUsername.length > 0) {
        // Handle collision, append a random string or timestamp (for now, just log)
        console.warn('Generated username collision detected. This should be rare.');
        // For a robust solution, you might want a loop here with a random suffix
      }

      const [insertResult] = await db.execute(
        'INSERT INTO users (username, kakao_id, nickname) VALUES (?, ?, ?)',
        [generatedUsername, kakao_id, generatedNickname]
      );
      const newUserId = insertResult.insertId;
      console.log('New user registered with ID:', newUserId);

      // Retrieve the newly created user
      [users] = await db.execute('SELECT * FROM users WHERE id = ?', [newUserId]);
      user = users[0];
    }

    // 4. Generate JWT
    const token = jwt.sign(
      { id: user.id, username: user.username, kakao_id: user.kakao_id, nickname: user.nickname },
      process.env.JWT_SECRET,
      { expiresIn: '1h' } // Token expires in 1 hour
    );
    console.log('JWT generated:', token);


    console.log('User logged in/registered:', user);
    res.status(200).json({
      message: 'Kakao login successful',
      token, // Return the JWT
      user: {
        id: user.id,
        username: user.username,
        kakao_id: user.kakao_id,
        nickname: user.nickname,
      },
    });

  } catch (error) {
    console.error('Error during Kakao login:', error.response ? error.response.data : error.message);
    res.status(500).json({ message: 'Kakao login failed', error: error.response ? error.response.data : error.message });
  }
});

module.exports = app;

