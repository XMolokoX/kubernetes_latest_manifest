CREATE TABLE users (
	user_id VARCHAR ( 50 ) PRIMARY KEY,
	user_name VARCHAR ( 50 ) NOT NULL,
	password VARCHAR ( 50 ) NOT NULL,
	email VARCHAR ( 255 ) NOT NULL
);

INSERT INTO users(user_id, user_name, password, email) VALUES ('U001', 'User 001', 'U1234', 'user01@gmail.com');
INSERT INTO users(user_id, user_name, password, email) VALUES ('U002', 'User 002', 'U1234', 'user02@gmail.com');
INSERT INTO users(user_id, user_name, password, email) VALUES ('U003', 'User 003', 'U1234', 'user03@gmail.com');
INSERT INTO users(user_id, user_name, password, email) VALUES ('U004', 'User 004', 'U1234', 'user04@gmail.com');
INSERT INTO users(user_id, user_name, password, email) VALUES ('U005', 'User 005', 'U1234', 'user05@gmail.com');