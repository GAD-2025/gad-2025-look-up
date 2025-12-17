USE lookup_db;

-- users 먼저
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

CREATE TABLE `users` (
  `id` varchar(255) NOT NULL,
  `nickname` varchar(255) NOT NULL,
  `kakao_id` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `kakao_id` (`kakao_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `users`
LOCK TABLES `users` WRITE;
INSERT INTO `users` VALUES ('gad123','영주','12345','2025-12-02 11:07:17');
UNLOCK TABLES;

CREATE TABLE `posts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `image_path` varchar(255) NOT NULL,
  `caption` text,
  `is_video` tinyint(1) DEFAULT '0',
  `user_id` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `posts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

