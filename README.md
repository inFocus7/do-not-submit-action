# do-not-submit-action
Fail CI if a keyword is found in any of the changed files.

## Action Definition

| Input   | Description | Default Value |
|----|----|----|
| keyword  | The keyword to search for in the file changes. | `DO_NOT_SUBMIT` |
| should_fail | If the Github Action should fail if `keyword` is found. | `true` |
| check_list  | A comma-separated list of regex-supported files to search for the keyword in | `"*"` |
| ignore_list | A comma-seperated list of regex-supported files to NOT search. Takes precedence over the `check_list`. | `""` |

_**Note:** The `check_list` and `ignore_list` parameters should be wrapped in quotes if using wildcards._

## Example Usages

### Use Case: Checking every modified file
On a run without any parameters set, this performs a check for the default keyword (`DO_NOT_SUBMIT`) on **all** files that were modified. 
No files are ignored.
If any instances are found, the action will fail.
```
name: Run Do Not Submit Action
on:
  pull_request:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-22.04
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - name: Run do-not-submit action
      uses: infocus7/do-not-submit-action@latest
```

### Use Case: Checking for files based on file extensions
The following checks in `.go`, `.proto`, and `go.mod` files for the default keyword (`DO_NOT_SUBMIT`). 
No files are ignored.
If any instances are found, the action will fail.
```
name: Run Do Not Submit Action
on:
  pull_request:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-22.04
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - name: Run do-not-submit action
      uses: infocus7/do-not-submit-action@latest
      with:
        check_list: '"*.go,*.proto,go.mod"'
```


### Use Case: Specific searches
The following code searches for the keyword `TODO`.
All files in the `data` folder, as well as `go.mod` files are searched. 
The files `data/file_1` and `data/file_2` are ignored, and therefore not searched.
Since `should_fail` is set to `false`: if any instances of the keyword are found, the Github Action will still pass with a warning.
```
name: Run Do Not Submit Action
on:
  pull_request:
    branches:
      - main
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-22.04
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - name: Run do-not-submit action
      uses: infocus7/do-not-submit-action@latest
      with:
        keyword: 'TODO'
        check_list: '"data/*,go.mod"'
        ignore_list: '"data/file_1,data/file_2"'
        should_fail: 'false'
```
