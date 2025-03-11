# World Cup Database

This is a practice project completed as part of the freeCodeCamp Relational Database course. It demonstrates skills in Bash scripting, PostgreSQL database management, and Git version control by importing World Cup match data from a CSV file into a database and running various SQL queries to analyze the data.

## Project Overview

The project consists of:
- A Bash script to set up a PostgreSQL database and import match data from `games.csv`.
- A query script to extract statistics and insights from the database.
- Verification scripts and files to ensure the output matches expected results.

## Files

- **`insert_data.sh`**:
  - Creates a `games` table in the `worldcup` database (or `worldcuptest` if run with `test` argument).
  - Imports match data from `games.csv` into the table, with error checking and validation.
  - Usage: `./insert_data.sh [test]`

- **`games.csv`**:
  - Contains World Cup match data (2014 and 2018 tournaments) with columns: `year`, `round`, `winner`, `opponent`, `winner_goals`, `opponent_goals`.

- **`queries.sh`**:
  - Runs SQL queries against the `worldcup` database to display statistics like total goals, averages, and champions.
  - Output matches the format in `expected_output.txt`.
  - Usage: `./queries.sh`

- **`expected_output.txt`**:
  - The expected output of `queries.sh` for verification against the actual database results.

- **`actual_output.txt`**:
  - Generated output from running `queries.sh`, used for diffing with `expected_output.txt`.

- **`diff specify_result.txt`**:
  - Stores the result of comparing `actual_output.txt` and `expected_output.txt` with `diff`. An empty file indicates a perfect match.

- **`check_output.sh`**:
  - Automates running `queries.sh` and comparing its output with `expected_output.txt` using `diff`.
  - Usage: `./check_output.sh`

- **`.gitignore`**:
  - Excludes temporary files like `.freeCodeCamp/` directories from version control.

## Setup Instructions

### Prerequisites
- PostgreSQL installed and running.
- Gitpod or a local Bash environment.
- GitHub repository cloned: `git clone https://github.com/Exstee/worldcup-database.git`.

### Steps
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Exstee/worldcup-database.git
   cd worldcup-database
   ```

2. **Set Up the Database**:
   - Ensure PostgreSQL is running with a user `freecodecamp` and database `worldcup` (or `postgres`/`worldcuptest` for test mode).
   - Run the insert script:
     ```bash
     chmod +x insert_data.sh
     ./insert_data.sh
     ```
     - Use `./insert_data.sh test` for the test database.

3. **Run Queries**:
   ```bash
   chmod +x queries.sh
   ./queries.sh
   ```

4. **Verify Output**:
   - Generate actual output:
     ```bash
     ./queries.sh > actual_output.txt
     ```
   - Compare with expected output:
     ```bash
     chmod +x check_output.sh
     ./check_output.sh
     ```
     - If `diff_result.txt` is empty, the output matches expectations.

## Database Schema

The `games` table has the following structure:
- `game_id` (SERIAL PRIMARY KEY)
- `year` (INT NOT NULL)
- `round` (VARCHAR(50) NOT NULL)
- `winner` (VARCHAR(50) NOT NULL)
- `opponent` (VARCHAR(50) NOT NULL)
- `winner_goals` (INT NOT NULL)
- `opponent_goals` (INT NOT NULL)
- `UNIQUE (year, round, winner, opponent)`

## Queries

The `queries.sh` script runs the following analyses:
- Total goals by winning teams.
- Total goals by both teams combined.
- Average goals (winning teams, both teams, rounded).
- Most goals in a single game.
- Games where winners scored > 2 goals.
- 2018 champion.
- Teams in 2014 Eighth-Final.
- Unique winning teams.
- All champions by year.
- Teams starting with "Co".

## Verification

The `check_output.sh` script ensures the output of `queries.sh` matches `expected_output.txt`, confirming the database and queries work as intended.

## License

This project is licensed under a [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).
```
