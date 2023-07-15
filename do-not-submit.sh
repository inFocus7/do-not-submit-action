#!/bin/bash

# do-not-submit.sh takes the following arguments
# 1. The keyword to cause a failure on
# 2. A list (as a string) representing which files to check for the keyword.
# 3. (optional) A list (as a string) representing which files to NOT check for the keyword.
# 4. A list of modified files to check for the keyword.
#
# If the keyword is present, the script exits with -1.
# This initial implementation only checks files for single-line comments.

if [[ "$#" -lt 4 ]]; then
  echo "Usage: $0 keyword check_list ignore_list filename [filenames ...]"
  exit -1
fi

NEWLINE=$'\n'
OUTPUT=""

KEYWORD=$1
CHECK_LIST=$2
IGNORE_LIST=$3
# Gets the rest of the arguments - which should be the list of files - as an array.
FILES=("${@:4}")

# TODO: What would be a good separator? `,`, `|`, or google's way and use `\n` here? (https://github.com/google-github-actions/get-secretmanager-secrets#inputs)
IFS=',' read -ra check_list_array <<< "$CHECK_LIST"
IFS=',' read -ra ignore_list_array <<< "$IGNORE_LIST"

# O(N+M), where N is the number of ignored checks, and M is the number of checks.
file_matches_check() {
  local filename=$1

  # Checking that we shouldn't ignore the file first.
  # When no ignore list is set, it is ''. Make sure this doesn't match anything in that case.
  for ignore in "${ignore_list_array[@]}"; do
    if [[ "$filename" == $ignore ]]; then
      return -1
    fi
  done

  for check in "${check_list_array[@]}"; do
    if [[ "$filename" == $check ]]; then
      return 0
    fi
  done
  return -1
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
    go|proto|java|js|ts|cpp|c|php)
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

file_count=0
# TODO: We could possibly do an approach using `grep` https://github.com/inFocus7/do-not-submit-action/issues/2
for filename in "${FILES[@]}"; do
  if file_matches_check "$filename"; then
    ((file_count++))
    line_number=1
    DO_NOT_SUBMIT_REGEX=$(get_do_not_submit_regex "$filename")
    # `read` reads lines with newline characters, so we add the check that $line is not empty as well to handle the last line.
    while IFS= read -r line || [[ -n $line ]]; do
      if [[ "$line" =~ $DO_NOT_SUBMIT_REGEX ]]; then
        OUTPUT="${OUTPUT}$filename:$line_number contains $KEYWORD${NEWLINE}"
      fi
      ((line_number++))
    done <"$filename"
  fi
done

if [[ "$OUTPUT" == "" ]]; then
  echo "$file_count files checked, none contained $KEYWORD"
  exit 0
else
  echo "$OUTPUT"
  exit -1
fi
