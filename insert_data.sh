#!/bin/bash

# Script to insert data from games.csv into the 'worldcup' database

# Set initial PSQL command to connect to default postgres database
if [[ $1 == "test" ]]; then
  DB_NAME="worldcuptest"
  PSQL="psql --username=postgres --dbname=postgres -t --no-align -c"
else
  DB_NAME="worldcup"
  PSQL="psql --username=freecodecamp --dbname=postgres -t --no-align -c"
fi

echo "Initial PSQL is set to: $PSQL"

# Check if the target database exists, create if it doesn't
DB_EXISTS=$($PSQL "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" 2>/dev/null)
if [[ -z "$DB_EXISTS" ]]; then
  echo "Creating database: $DB_NAME"
  if [[ $1 == "test" ]]; then
    psql --username=postgres -c "CREATE DATABASE $DB_NAME;" 2>/dev/null
  else
    psql --username=freecodecamp -c "CREATE DATABASE $DB_NAME;" 2>/dev/null
  fi
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create database $DB_NAME"
    exit 1
  fi
else
  echo "Database $DB_NAME already exists"
fi

# Update PSQL command to connect to the target database
if [[ $1 == "test" ]]; then
  PSQL="psql --username=postgres --dbname=$DB_NAME -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=$DB_NAME -t --no-align -c"
fi

echo "PSQL is now set to: $PSQL"

# Test database connection
DB_CURRENT=$($PSQL "SELECT current_database();" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "Error: Could not connect to the database. Details: $DB_CURRENT"
  exit 1
else
  echo "Connected to database: $DB_CURRENT"
fi

# Check if games.csv exists
if [[ ! -f games.csv ]]; then
  echo "Error: games.csv not found in the current directory!"
  exit 1
fi

echo "Setting up database schema..."

# Drop existing tables if they exist
$PSQL "DROP TABLE IF EXISTS games CASCADE;" 2>/dev/null
$PSQL "DROP TABLE IF EXISTS teams CASCADE;" 2>/dev/null

# Create teams table
$PSQL "CREATE TABLE teams (
  team_id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
);" 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to create teams table."
  exit 1
fi

# Create games table
$PSQL "CREATE TABLE games (
  game_id SERIAL PRIMARY KEY,
  year INT NOT NULL,
  round VARCHAR(50) NOT NULL,
  winner_id INT NOT NULL,
  opponent_id INT NOT NULL,
  winner_goals INT NOT NULL,
  opponent_goals INT NOT NULL,
  FOREIGN KEY (winner_id) REFERENCES teams(team_id),
  FOREIGN KEY (opponent_id) REFERENCES teams(team_id)
);" 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to create games table."
  exit 1
fi

echo "Database schema setup complete."

# Process team data
echo "Importing team data..."
TEAM_COUNTER=0
TEAM_FAILURES=0

# Get unique teams from games.csv, skipping header row
mapfile -t UNIQUE_TEAMS < <(awk -F, 'NR>1 {print $3"\n"$4}' games.csv | tr -d '"' | sort | uniq | grep -v '^$')

# Debug: Print number of teams and their names
echo "Found ${#UNIQUE_TEAMS[@]} unique teams:"
printf '%s\n' "${UNIQUE_TEAMS[@]}"

for TEAM in "${UNIQUE_TEAMS[@]}"; do
  if [[ -n "$TEAM" ]]; then
    # Check if team already exists to avoid UNIQUE constraint errors
    EXISTS=$($PSQL "SELECT 1 FROM teams WHERE name='$TEAM';")
    if [[ -z "$EXISTS" ]]; then
      $PSQL "INSERT INTO teams(name) VALUES('$TEAM');"
      if [[ $? -eq 0 ]]; then
        ((TEAM_COUNTER++))
        echo "Inserted team: $TEAM"
      else
        echo "Failed to insert team: $TEAM"
        ((TEAM_FAILURES++))
      fi
    else
      echo "Team already exists: $TEAM"
    fi
  else
    echo "Skipping empty team name"
  fi
done

echo "Successfully imported $TEAM_COUNTER teams with $TEAM_FAILURES failures."

# Verify team count
TEAM_COUNT=$($PSQL "SELECT COUNT(*) FROM teams;")
echo "Total teams in database: $TEAM_COUNT"
if [[ "$TEAM_COUNT" -ne 24 ]]; then
  echo "Error: Expected 24 teams, but found $TEAM_COUNT"
  exit 1
fi

# Process game data
echo "Importing game data..."
GAME_COUNTER=0
GAME_FAILURES=0

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
    ((GAME_FAILURES++))
    continue
  fi

  # Get team IDs
  WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$winner';")
  OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$opponent';")

  if [[ -z "$WINNER_ID" || -z "$OPPONENT_ID" ]]; then
    echo "Failed to find team IDs for: $winner vs $opponent"
    ((GAME_FAILURES++))
    continue
  fi

  # Insert game
  $PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) 
         VALUES($year, '$round', $WINNER_ID, $OPPONENT_ID, $winner_goals, $opponent_goals);"
  if [[ $? -eq 0 ]]; then
    ((GAME_COUNTER++))
  else
    echo "Failed to insert game: $year, $round, $winner, $opponent, $winner_goals, $opponent_goals"
    ((GAME_FAILURES++))
  fi
done < games.csv

echo "Successfully imported $GAME_COUNTER games with $GAME_FAILURES failures."
echo "Data import completed!"

# Final counts for verification
echo "Total teams in database: $($PSQL "SELECT COUNT(*) FROM teams;")"
echo "Total games in database: $($PSQL "SELECT COUNT(*) FROM games;")"

echo "Done!"
