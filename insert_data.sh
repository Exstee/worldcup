#!/bin/bash

# Script to insert data from games.csv into the 'worldcup' database

# Set PSQL command based on argument
if [[ $1 == "test" ]]; then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

echo "PSQL is set to: $PSQL"

# Test database connection
DB_NAME=$($PSQL "SELECT current_database();" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "Error: Could not connect to the database. Details: $DB_NAME"
  exit 1
else
  echo "Connected to database: $DB_NAME"
fi

# Check if games.csv exists
if [[ ! -f games.csv ]]; then
  echo "Error: games.csv not found in the current directory!"
  exit 1
fi

echo "Setting up database schema..."

# Drop existing table if it exists
$PSQL "DROP TABLE IF EXISTS games CASCADE;" 2>/dev/null

# Create a simple games table with a primary key and unique constraint
$PSQL "CREATE TABLE games (
  game_id SERIAL PRIMARY KEY,
  year INT NOT NULL,
  round VARCHAR(50) NOT NULL,
  winner VARCHAR(50) NOT NULL,
  opponent VARCHAR(50) NOT NULL,
  winner_goals INT NOT NULL,
  opponent_goals INT NOT NULL,
  UNIQUE (year, round, winner, opponent)
);" 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to create games table."
  exit 1
fi

echo "Database schema setup complete."

# Process game data
echo "Importing game data..."
COUNTER=0
FAILURES=0

# Read CSV and insert rows
while IFS=, read -r year round winner opponent winner_goals opponent_goals; do
  if [[ "$year" == "year" ]]; then
    continue
  fi
  year=$(echo "$year" | tr -d '"')
  round=$(echo "$round" | tr -d '"')
  winner=$(echo "$winner" | tr -d '"')
  opponent=$(echo "$opponent" | tr -d '"')
  winner_goals=$(echo "$winner_goals" | tr -d '"')
  opponent_goals=$(echo "$opponent_goals" | tr -d '"')
  # Validate data
  if [[ -z "$year" || -z "$round" || -z "$winner" || -z "$opponent" || -z "$winner_goals" || -z "$opponent_goals" ]]; then
    echo "Skipping invalid row: $year, $round, $winner, $opponent, $winner_goals, $opponent_goals"
    ((FAILURES++))
    continue
  fi
  $PSQL "INSERT INTO games(year, round, winner, opponent, winner_goals, opponent_goals) 
         VALUES($year, '$round', '$winner', '$opponent', $winner_goals, $opponent_goals);" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    ((COUNTER++))
  else
    echo "Failed to insert: $year, $round, $winner, $opponent, $winner_goals, $opponent_goals"
    ((FAILURES++))
  fi
done < games.csv

echo "Successfully imported $COUNTER games with $FAILURES failures."
echo "Data import completed!"

# Final count for verification
echo "Total games in database: $($PSQL "SELECT COUNT(*) FROM games;")"

echo "Done!"