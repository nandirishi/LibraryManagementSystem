-- Create Database
CREATE DATABASE IF NOT EXISTS library_db;
USE library_db;

-- 1. Users Table
CREATE TABLE Users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('ADMIN', 'MEMBER') NOT NULL DEFAULT 'MEMBER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Books Table
CREATE TABLE Books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    published_year INT,
    total_copies INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    -- Prevent available copies from dropping below zero at the DB level
    CONSTRAINT chk_available_copies CHECK (available_copies >= 0 AND available_copies <= total_copies)
);

-- 3. Authors Table
CREATE TABLE Authors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    bio TEXT
);

-- 4. Book_Authors (Junction Table)
CREATE TABLE Book_Authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES Books(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES Authors(id) ON DELETE CASCADE
);

-- 5. Transactions Table
CREATE TABLE Transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    user_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status ENUM('BORROWED', 'RETURNED', 'OVERDUE') NOT NULL DEFAULT 'BORROWED',
    FOREIGN KEY (book_id) REFERENCES Books(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE RESTRICT
);

-- 6. Fines Table
CREATE TABLE Fines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (transaction_id) REFERENCES Transactions(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- TRIGGERS: Automated Inventory Management
-- ---------------------------------------------------------

DELIMITER $$

-- Trigger 1: Decrement available_copies on new loan
CREATE TRIGGER trg_after_loan_insert
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.status = 'BORROWED' THEN
        UPDATE Books 
        SET available_copies = available_copies - 1 
        WHERE id = NEW.book_id;
    END IF;
END$$

-- Trigger 2: Increment available_copies on return
CREATE TRIGGER trg_after_loan_update
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF OLD.status = 'BORROWED' AND NEW.status = 'RETURNED' THEN
        UPDATE Books 
        SET available_copies = available_copies + 1 
        WHERE id = NEW.book_id;
    END IF;
END$$

DELIMITER ;