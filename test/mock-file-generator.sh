#!/bin/bash

# Generate 1.5k files, each with 1-5k lines, and optional comments.
# These will be used to test the `do-not-submit` action (both for performance & the action itself on github).
# Will remove afterward cause this is unnecessary, but I didn't want to use other people's repo or code for testing.

extensions=("go" "py" "cpp" "c" "js" "ts" "jsx" "tsx")
keyword="DO_NOT_SUBMIT"
lorem_ipsum="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
mkdir -p src

get_code() {
  local extension="$1"
  local code_output=""
  local comment_style=""
  case $extension in
    go)
      code_output=$(printf "package main\n\nfunc main() {\n\tfmt.Println(\"Hello, World!\")\n}\n")
      comment_style="//"
      ;;
    py)
      code_output=$(printf "print(\"Hello, World!\")\n")
      comment_style="#"
      ;;
    cpp)
      code_output=$(printf "#include <iostream>\n\nint main() {\n\tstd::cout << \"Hello, World!\" << std::endl;\n\treturn 0;\n}\n\n")
      comment_style="//"
      ;;
    c)
      code_output=$(printf "#include <stdio.h>\n\nint main() {\n\tprintf(\"Hello, World!\");\n\treturn 0;\n}\n\n")
      comment_style="//"
      ;;
    js|ts|tsx|jsx)
      code_output=$(printf "console.log(\"Hello, World!\");\n")
      comment_style="//"
      ;;
    *)
      code_output=$(printf "echo \"Hello, World!\"\n")
      comment_style=""
      ;;
  esac

  local linesOfCode=$((1 + RANDOM % 5000))
  for ((j=1; j<=linesOfCode; j++)) do
    if [[ $((RANDOM % 5000)) -eq 0 ]]; then
      code_output+=$(printf "\n$comment_style $keyword\n")
    else
      portion_of_lorem_ipsum_string=$((RANDOM % (${#lorem_ipsum} - 1) + 1))
      code_output+=$(printf "\n$comment_style ${lorem_ipsum:0:$portion_of_lorem_ipsum_string}\n")
    fi
  done

  echo "$code_output"
}

for ((i=1; i<=1500; i++)) do
  extension=${extensions[$RANDOM % ${#extensions[@]} ]}
  filename="file_$i.$extension"
  get_code "$extension" > "src/$filename"
done