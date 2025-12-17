USE lookup_db;

-- users 먼저
CREATE TABLE users (
  id VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  nickname VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

-- posts 나중
CREATE TABLE posts (
  id INT NOT NULL AUTO_INCREMENT,
  image_path VARCHAR(255) NOT NULL,
  caption TEXT,
  is_video TINYINT(1) DEFAULT 0,
  user_id VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY user_id (user_id),
  CONSTRAINT posts_ibfk_1
    FOREIGN KEY (user_id) REFERENCES users(id)
);

