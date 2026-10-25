# Air Traffic Control

Air Traffic Control sends links opened outside Dia to the correct Dia profile. It replaces the Arc feature with the same name.

## Language

**Link**:
A web URL that the user opens from an app other than Dia, or that comes from another device through Handoff. A Link from Handoff has no Source app.
_Avoid_: URL event, request

**Profile**:
A Dia profile, identified by its exact display name in Dia (for example, `Personal` or `Work`).
_Avoid_: Space, account

**Rule**:
A URL pattern, a Source app, or both, and the Profile that a matching Link opens in. When a Rule has both, the Link must match both. The first matching Rule wins.
_Avoid_: Route

**URL pattern**:
A domain with an optional path prefix. The domain matches itself and all subdomains. The path prefix matches only on a full path segment.
_Avoid_: Contains, wildcard

**Source app**:
The app in which the user opened the Link.
_Avoid_: Opener, sender

**Pass-through**:
What happens to a Link that matches no Rule: Dia opens it as usual, in the Profile that is active at that time.
_Avoid_: Default, fallback
