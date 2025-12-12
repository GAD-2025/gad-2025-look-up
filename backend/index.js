// 필요 모듈
require('dotenv').config();

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const app = express();

const corsOptions = {
  origin: 'http://localhost:58747',
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
app.use(express.json());

// MySQL 연결
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,        
  password: process.env.DB_PASSWORD, 
  database: process.env.DB_NAME
});

// ✅ 아이디 중복 체크 API
app.post('/check-id-duplication', async (req, res) => {
  const { id } = req.body;

  console.log('📩 요청받은 아이디:', id);

  try {
    const [rows] = await pool.query(
      'SELECT COUNT(*) AS count FROM users WHERE id = ?',
      [id]
    );

    const isDuplicated = rows[0].count > 0;

    console.log('🔎 DB 조회 결과 → isDuplicated:', isDuplicated);

    res.json({ isDuplicated });
  } catch (err) {
    console.error('❌ DB 에러:', err);
    res.status(500).json({ error: 'DB error' });
  }
});

app.listen(3000, () => {
  console.log('🚀 서버 실행 중 → http://localhost:3000');
});
