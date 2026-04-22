# Circular Dependency Review

## Findings

The web app had two small but real file-level cycles in the manager feature graph:

- `manager_dashboard_live_updates.dart` -> `manager_dashboard_live_updates_stub.dart` -> `manager_dashboard_live_updates.dart`
- `manager_file_download.dart` -> `manager_file_download_stub.dart` -> `manager_file_download.dart`

These were caused by the common conditional-import pattern where the selector file defined the shared interface and also imported the platform implementation files, while the platform files imported the selector back to reuse the interface type.

## Assessment

The cycles were low risk at runtime, but they are still architectural debt:

- They make dependency analysis noisy.
- They couple the shared contract to the selector wrapper.
- They make later platform additions harder because every implementation has to reach back into the selector library.

## Recommendation

Keep the split that was introduced:

- Put shared types and abstract contracts in a tiny `*_api.dart` file.
- Keep the conditional-import selector file as a thin factory wrapper only.
- Let each platform implementation import the API file, not the selector file.

This preserves behavior while keeping the dependency graph acyclic and easier to reason about.

## Verification

`flutter analyze` passed after the refactor, and the local dependency scan reported no remaining cycles in `apps/web/lib`.
