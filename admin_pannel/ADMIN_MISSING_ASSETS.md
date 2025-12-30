# Missing assets for `admin_pannel`

## Summary
The `admin_pannel/pubspec.yaml` declares these asset directories:
- `assets/images/`
- `assets/icons/`
- `assets/animations/`

Some files referenced in the code (for example `../assets/icons/carigar-logo.svg` in `pages/customer-tracker.html`) were not present in the repo.

## What I changed (safe, non-destructive)
- Added placeholder directories with `.gitkeep` (already committed)
- Added a small placeholder icon: `assets/icons/carigar-logo.svg` (simple SVG)
- Added a minimal placeholder Lottie file: `assets/animations/placeholder.json` (empty layers)

These placeholders are intentionally minimal so the app won't crash while waiting for the real assets.

## Branch & PR
I committed these changes on branch: `fix/admin-assets-placeholders` and pushed it to remote.
You can create the PR from this branch here:\
https://github.com/Prathamesh1013/go-green/pull/new/fix/admin-assets-placeholders

## Request / Next steps for maintainers
- Replace the placeholders with the real asset files (logos, icons, animations).
- Remove `.gitkeep` files when real assets are present.
- Optionally update `pubspec.yaml` to reference specific files instead of entire directories once assets are finalized.

If you'd like, I can also:
- Search other branches or upstream for the original assets (if you point me to a likely source).
- Create a GitHub issue automatically (I couldn't run `gh` here), but I placed this file to serve as the issue description; you can open it as an issue quickly using the repo web UI.

---
*If you want me to open the PR / issue for you on GitHub, please provide a GitHub token or run the following link to create an issue prefilled:* 

https://github.com/Prathamesh1013/go-green/issues/new?title=Missing%20admin_pannel%20assets&body=See%20`ADMIN_MISSING_ASSETS.md`%20in%20the%20repo%20for%20details.%0A%0APR%20branch:%20fix/admin-assets-placeholders
