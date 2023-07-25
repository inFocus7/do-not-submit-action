#!/bin/bash

# do-not-submit.sh takes the following arguments
# 1. The keyword to cause a failure on
# 2. Whether the action should pass or fail if a KEYWORD is found ("fail", "warn")
# 2. A list (as a string) representing which files to check for the keyword.
# 3. (optional) A list (as a string) representing which files to NOT check for the keyword.
# 4. A list of modified files to check for the keyword.
#
# If the keyword is present, the script exits with 1.
# This initial implementation only checks files for single-line comments.

if [[ "$#" -lt 5 ]]; then
  echo "Usage: $0 keyword failure_type check_list ignore_list filename [filenames ...]"
  exit 1
fi

NEWLINE=$'\n'
OUTPUT=""

KEYWORD=$1
FAILURE_TYPE=$2
CHECK_LIST=$3
IGNORE_LIST=$4
# Gets the rest of the arguments - which should be the list of files - as an array.
FILES=("${@:5}")

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
}

for filename in "${FILES[@]}"; do
  if file_matches_check "$filename"; then
    DO_NOT_SUBMIT_REGEX=$(get_do_not_submit_regex "$filename")
    grep_output=$(grep -Hn "$DO_NOT_SUBMIT_REGEX" "$filename")
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

  if [[ "$FAILURE_TYPE" == "fail" ]]; then
    echo "::error ::Instances of \"$KEYWORD\" were found in files."
    exit 1
  elif [[ "$FAILURE_TYPE" == "warn" ]]; then
    echo "::warning ::Instances of \"$KEYWORD\" were found in files, but the action is configured to warn instead of fail."
    exit 0
  fi
fi

exit 0
