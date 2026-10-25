# Agent rules

## Writing

- Write all docs and code comments in ASD-STE100 Simplified Technical English (STE). This includes `README.md`, `AGENTS.md`, and `GLOSSARY.md`.
- Use the terms in `GLOSSARY.md`. When a term changes, update `GLOSSARY.md` in the same change.
- When you change a log message, a rule field, or the install steps, update `README.md` in the same change.
- `README.md` is for users. Put notes for maintainers in this file, or in a comment near the related code.

## Code

- The app is one Swift file. Build it with `./install.sh` (`xcrun swiftc`, no Xcode project, no Swift package).
- Log only the host, the source app, and the result. Full URLs can contain login tokens, so they must never go into the log.
- Put all values into AppleScript through `appleScriptString`.
- Pass-through must open the link with Dia by its bundle ID. If it opens the link with the default browser, the link comes back to this app and loops.
- `install.sh` makes `AppIcon.icns` from `Resources/AppIcon.png`. macOS keeps old icons in a cache. If the Dock shows the old icon after a change, run `killall Dock`.

## Testing

Each rebuild gets a new ad-hoc signature, so macOS asks for the Automation permission again.
