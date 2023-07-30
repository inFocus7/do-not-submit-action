#!/bin/bash

# do-not-submit.sh takes the following arguments:
# -k (optional) Keyword to cause failure on. Defaults to "DO_NOT_SUBMIT".
# -w (optional) If toggled, the script will exit with code 0 (non-failure) when keyword instances are found..
# -x (optional) If toggled, the search type to perform will be set to search for keyword instances anywhere in the files.
# -c (optional) <list> A list (as a comma-separated string) representing which files to check for the keyword. Defaults to check all files passed.
# -i (optional) <list> A list (as a comma-separated string) representing which files to NOT check for the keyword.
# filenames... A list of modified files to check for the keyword.

help() {
  echo "Usage: $0 [-k <keyword>] [-w] [-x] [-c <list>] [-i <list>] filenames..."
}

# Defaults
SEARCH_TYPE="smart"
FAILURE_TYPE="fail"
CHECK_LIST="*"
KEYWORD="DO_NOT_SUBMIT"
IGNORE_LIST=""

NEWLINE=$'\n'
OUTPUT=""

# Parsing command-line options
while getopts ":k:w:x:c:i:" opt; do
  case $opt in
    k)
      KEYWORD="$OPTARG"
      ;;
    w)
      FAILURE_TYPE="warn"
      ;;
    x)
      SEARCH_TYPE="any"
      ;;
    c)
      CHECK_LIST="$OPTARG"
      ;;
    i)
      IGNORE_LIST="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      help
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      help
      exit 1
      ;;
  esac
done

if [[ "$KEYWORD" == "" ]]; then
  echo "::error The keyword MUST NOT be empty. Exiting."
  exit 1
fi

# Shift to skip over processed options
shift $((OPTIND - 1))

if [[ $# -eq 0 ]]; then
  echo "No files provided." >&2
  help
  exit 1
fi

# The remaining arguments are the filenames
FILES=("$@")

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
