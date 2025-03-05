#!/bin/bash

read -p "Enter MySQL username: " MYSQL_USER

read -p "Enter the database name: " MYSQL_DATABASE

read -s -p "Enter MySQL password (leave blank if none): " MYSQL_PASSWORD
echo

if [ -z "$MYSQL_PASSWORD" ]; then
    MYSQL_CMD="mysql -u $MYSQL_USER -D $MYSQL_DATABASE"
else
    MYSQL_CMD="mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -D $MYSQL_DATABASE"
fi

SQL_SCRIPT="
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;

USE $MYSQL_DATABASE;

CREATE TABLE IF NOT EXISTS todos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    description TEXT NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO todos (description, completed) VALUES 
('Buy milk', FALSE),
('Study Bash', TRUE),
('Finish project', FALSE);
"

$MYSQL_CMD -e "$SQL_SCRIPT"

echo "Database '$MYSQL_DATABASE' and the 'todos' table have been created successfully, with records inserted!"