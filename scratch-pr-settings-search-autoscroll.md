# Improve Settings search keyboard navigation

## Summary

Keep the selected Settings search result visible while navigating with the keyboard.

## Changes

- Scroll the Settings sidebar when the selected result moves outside the viewport.
- Apply a small edge margin around the selected result.
- Keep the first result visible when a new search query is entered.

## Validation

- `git diff --check`
- `make lint-qml` *(blocked: `quickshell/.qmlls.ini` is not generated in this checkout)*
