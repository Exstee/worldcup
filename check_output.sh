#!/bin/bash

# Run query script and save output
./queries.sh > actual_output.txt

# Compare with expected output
diff actual_output.txt expected_output.txt > diff_result.txt

if [[ -s diff_result.txt ]]; then
  echo "Differences found:"
  cat diff_result.txt
else
  echo "No differences found—output matches expected!"
fi