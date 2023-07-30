#!/bin/bash

# do-not-submit.sh takes the following arguments:
# 1. The keyword to cause a failure on
# 2. Whether the action should pass or fail if a KEYWORD is found ("fail", "warn")
# 3. The type of search to perform ("smart", anything)
# 4. A list (as a string) representing which files to check for the keyword.
# 5. (optional) A list (as a string) representing which files to NOT check for the keyword.
# 6+ Modified files to check for the keyword.
#
# If the keyword is present, the script exits with 1.
# This initial implementation only checks files for single-line comments.

if [[ "$#" -lt 6 ]]; then
  echo "Usage: $0 keyword failure_type search_type check_list ignore_list filename [filenames ...]"
  exit 1
fi

NEWLINE=$'\n'
OUTPUT=""

KEYWORD=$1
# Regardless of failure type we want to exit with 1 so user knows something went wrong.
if [[ "$KEYWORD" == "" ]]; then
  echo "::error The keyword MUST NOT be empty. Exiting."
  exit 1
fi
FAILURE_TYPE=$2
SEARCH_TYPE=$3
CHECK_LIST=$4
IGNORE_LIST=$5
# Gets the rest of the arguments - which should be the list of files - as an array.
FILES=("${@:6}")

IFS=',' read -ra check_list_array <<< "$CHECK_LIST"
IFS=',' read -ra ignore_list_array <<< "$IGNORE_LIST"

# O(N+M), where N is the number of ignored checks, and M is the number of checks.
total_files=${#FILES[@]}
files_checked=0
files_ignored=0
file_matches_check() {
  local filename=$1

  # Checking that we shouldn't ignore the file first.
  # When no ignore list is set, it is ''. Make sure this doesn't match anything in that case.
  for ignore in "${ignore_list_array[@]}"; do
    if [[ "$filename" == $ignore ]]; then
      ((files_ignored++))
      return 1
    fi
  done

  for check in "${check_list_array[@]}"; do
    if [[ "$filename" == $check ]]; then
      ((files_checked++))
      return 0
    fi
  done
  return 1
}

# TODO: Add support for inline comments at first, then add support for block comments at a later date.
# *.go, *.proto, *.java, *.js, *.ts, *.cpp, *.c, *.php: "//", "/* ... */"
# *.py: "#", """ ... """
# *.html: "<!-- ... -->"
# *.css, *.scss: "/* ... */"
# *.sh, *.yaml, *.yml: "#"
# TODO: How to handle markdown files? https://www.jamestharpe.com/markdown-comments/
get_do_not_submit_regex() {
  local filename="$1"

  case $SEARCH_TYPE in
    smart)
      # Gets the files extension after the last period. (e.g. "foo.bar.baz" -> "baz")
        local file_extension="${filename##*.}"

        case $file_extension in
          go|mod|proto|java|js|ts|cpp|c|php|tsx|jsx)
            echo "[[:space:]]*//[[:space:]]*$KEYWORD"
            ;;
          py)
            # Separating Python. When adding block comment support, Python has """ ... """ for block comments, which other's don't.
            echo "[[:space:]]*#[[:space:]]*$KEYWORD"
            ;;
          sh|yaml|yml)
            echo "[[:space:]]*#[[:space:]]*$KEYWORD"
            ;;
          *)
            # Default case, no matching file extension
            echo "[[:space:]]*$KEYWORD"
            ;;
        esac
      ;;
    *)
      # Default case, no matching search type, do a simple search for the keyword.
      echo "$KEYWORD"
      ;;
  esac
}

for filename in "${FILES[@]}"; do
  if file_matches_check "$filename"; then
    DO_NOT_SUBMIT_REGEX=$(get_do_not_submit_regex "$filename")
    # Extending grep support with (-E), so that a keyword of "EXAMPLE|DO_NOT_SUBMIT" will match both.
    grep_output=$(grep -HEn "$DO_NOT_SUBMIT_REGEX" "$filename")
    if [[ -n "$grep_output" ]]; then
      OUTPUT="${OUTPUT}$grep_output${NEWLINE}"
    fi
  fi
done

echo "--- $KEYWORD Search Results ---"
echo "From $total_files files, $files_checked files were searched, and $files_ignored files were ignored."
if [[ "$OUTPUT" == "" ]]; then
  echo "KEYWORD_MATCHED=false" >> "$GITHUB_OUTPUT"
  echo "No checked files contained \"$KEYWORD\"."
else
  echo "KEYWORD_MATCHED=true" >> "$GITHUB_OUTPUT"
  echo "Usages of $KEYWORD found in the following:"
  echo "$OUTPUT"

  # Get number of instances of the keyword found.
  num_instances=$(echo "$OUTPUT" | wc -l | tr -d '[:space:]')
  num_instances=$((num_instances - 1))

  if [[ "$FAILURE_TYPE" == "fail" ]]; then
    echo "::error ::$num_instances instance(s) of \"$KEYWORD\" were found in files."
    exit 1
  elif [[ "$FAILURE_TYPE" == "warn" ]]; then
    echo "::warning ::$num_instances instance(s) of \"$KEYWORD\" were found in files."
    exit 0
  fi
fi

exit 0
