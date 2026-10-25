# Air Traffic Control

Air Traffic Control opens links from other apps (for example, Slack or Mail) in the correct [Dia](https://www.diabrowser.com) profile. It replaces the Arc feature with the same name, which Dia does not have.

This project uses ideas from [michaelgallagher/dia-router](https://github.com/michaelgallagher/dia-router).

## How it works

Air Traffic Control is the macOS default browser. When you open a link, it reads your rules. The first rule that matches selects the profile, and Dia opens the link as a new tab in that profile. If no rule matches, Dia opens the link in the active profile.

Links that you open inside Dia do not go through Air Traffic Control.

Air Traffic Control also gets these links:

- Pages from your iPhone or iPad through Handoff. These links have no source app, so only `url` rules can match them.
- Links that you send to the Mac with AirDrop.

Air Traffic Control does not get these links:

- Sign-in windows in some apps (`ASWebAuthenticationSession`). Safari opens them, as it does when Dia is the default browser. Dia cannot send the result of the sign-in back to the app.
- iCloud Tabs. These show only in Safari.
- Links that you tap in iPhone Mirroring. These open on the iPhone.
- Universal Links. When an app claims a domain (for example, Zoom), macOS opens that app and not the default browser.

macOS shows an app as a default browser only if the app can open HTML files. Thus Air Traffic Control also accepts local HTML files, and it sends them to Dia with no rules.

## Requirements

- macOS 13 or later
- Dia, running, with one window
- Command Line Tools (`xcode-select --install`)

## Install

```bash
./install.sh
```

Then do these steps:

1. Open System Settings > Desktop & Dock > Default web browser, and select **Air Traffic Control**.
2. Open a link from another app. When macOS asks to let Air Traffic Control control Dia, click **Allow**.

Each rebuild gets a new signature, so macOS asks for this permission again.

## Rules

Write your rules in `rules.json` in this repo. Git ignores this file, because it can contain work domains. `install.sh` creates it from `rules.example.json`, and links `~/.config/air-traffic-control/rules.json` to it. Air Traffic Control reads the rules for each link, so you do not have to restart it or run `install.sh` after a change.

If you move this repo, run `install.sh` again to repair the link.

```json
{
  "rules": [
    { "url": "youtube.com", "app": "com.tinyspeck.slackmacgap", "profile": "Personal" },
    { "app": "com.tinyspeck.slackmacgap", "profile": "Work" },
    { "url": "github.com/acme", "profile": "Work" }
  ]
}
```

Each rule has a `profile` and one or both of these conditions:

- `url`: a domain with an optional path prefix. `github.com` matches `github.com` and all its subdomains. `github.com/acme` matches `/acme` and `/acme/...`, but not `/acme-other`.
- `app`: the bundle ID of the app where you open the link.

When a rule has both conditions, the link must match both. The first matching rule wins, so put specific rules above general rules.

`profile` must be the exact profile name in Dia. To see the names:

```bash
osascript -e 'tell application "Dia" to get name of profiles of front window'
```

To find the bundle ID of an app:

```bash
osascript -e 'id of app "Slack"'
```

## Debugging

Air Traffic Control writes to the macOS system log. It logs the host, the source app, and the result. It does not log full URLs.

Watch the log while you open a link:

```bash
log stream --level info --predicate 'subsystem == "com.satejbidvai.air-traffic-control"'
```

Show the log for the last 10 minutes:

```bash
log show --last 10m --info --predicate 'subsystem == "com.satejbidvai.air-traffic-control"'
```

Possible problems:

- **Cannot read rules**: `rules.json` is missing or is not valid JSON. All links open in the active profile until you correct it.
- **AppleScript failed**: the profile name is incorrect, Dia has no window, or macOS blocked the permission. Make sure the name agrees with the `osascript` output above. Then look in System Settings > Privacy & Security > Automation.
- **Source app is `unknown`**: the app did not send its identity with the link, or the link came through Handoff. Use a `url` rule for these links.
- **Handoff opens Safari**: Air Traffic Control is not the default browser, or Handoff is off in System Settings > General > AirDrop & Handoff.

To reset the Automation permission:

```bash
tccutil reset AppleEvents com.satejbidvai.air-traffic-control
```

## Uninstall

1. Set Dia as the default browser in System Settings > Desktop & Dock.
2. Remove the app and the rules:

   ```bash
   pkill -x AirTrafficControl
   rm -rf ~/Applications/"Air Traffic Control.app" ~/.config/air-traffic-control
   ```
