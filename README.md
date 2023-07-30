# do-not-submit-action
Fail CI if a keyword is found in any of the changed files.

## Action Definition

| Input        | Description                                                                                            | Default Value   |
|--------------|--------------------------------------------------------------------------------------------------------|-----------------|
| keyword      | The keyword to search for in the file changes. This parameter supports regex and allows multi-search.  | `DO_NOT_SUBMIT` |
| should_fail  | If the Github Action should fail if `keyword` is found.                                                | `true`          |
| smart_search | If the `keyword` should be searched within comments (smart), or as-is anywhere in the file.            | `true`          |
| check_list   | A comma-separated list of regex-supported files to search for the keyword in                           | `"*"`           |
| ignore_list  | A comma-seperated list of regex-supported files to NOT search. Takes precedence over the `check_list`. | `""`            |

_**Note:** The `check_list`, `ignore_list`, and `keyword` parameters should be wrapped in quotes if using wildcards or special regex-matching characters._

## Example Usages

### Use Case: Default usage
On a run without any parameters set, this performs a check for the default keyword (`DO_NOT_SUBMIT`) on **all** files that were modified. 
No files are ignored.
If any instances are found, the action will fail.
```yaml
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
```yaml
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
        # Search for the keyword in all files with the extensions `go` and `proto`, as well as `go.mod` files.
        check_list: '"*.go,*.proto,go.mod"'
```

### Use Case: Ignoring files
```yaml
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
        # Ignores all `md` and `yml` files when performing the `keyword` search.
        ignore_list: '"*.md,*.yml"'
```

### Use Case: Checking for ANY instance of the keyword
```yaml
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
        # Search for the keyword as-is, regardless of the file extension.
        smart_search: 'false'
```

### Use Case: Advanced searches
```yaml
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
        # Search for both `EXAMPLE` and `DO_NOT_SUBMIT`
        keyword: '"EXAMPLE|DO_NOT_SUBMIT"'
        # Search for the keyword in all files in the `data` folder, as well as `go.mod` files
        check_list: '"data/*,go.mod"'
        # Ignore the files `data/file_1` and `data/file_2`
        ignore_list: '"data/file_1,data/file_2"'
        # Succeed and warn in the action if any instances of the keyword are found
        should_fail: 'false'
```

## Limitations
- The action does not support searching for a keyword in a multi-line comment.
  - A workaround to this is using the `smart_search: false` parameter as shown in [Checking For Any Instance](#use-case-checking-for-any-instance-of-the-keyword).
  - This may not be a good workaround for all cases.
- Due to the nature of regex commands, any parameters using wildcards or special characters (ex. '|'), should be wrapped in quotes. So inputs need to be in the form of `'"<value>"'`
  - This is shown in the [Checking For Files Based On File Extensions](#use-case-checking-for-files-based-on-file-extensions) as well as in [Advanced Searches](#use-case-advanced-searches).
