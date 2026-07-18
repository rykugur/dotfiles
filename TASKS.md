
## Task 6 Report Evidence

- **zellij-exists** now returns:
  - 0 on match
  - 1 on no-match
  - 2 on invalid regex (e.g., "[")
- **zellij-create-or-attach** only creates/attaches if zellij-exists returns 1 (no-match).
- **Regression test** added and passing: tests/fish/zellij-regex.fish

