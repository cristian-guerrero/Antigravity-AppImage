# Google Antigravity AppImage

This repository contains an automated CI/CD pipeline to package **Google Antigravity** as an AppImage for Linux.

## How it works

1.  The GitHub Action [release.yml](.github/workflows/release.yml) runs on a schedule (every 12 hours) and can be triggered manually.
2.  It queries the Google Update API (Omaha protocol) to find the latest stable version of Antigravity.
3.  If a new version is detected, it downloads the official tarball, bundles it into an AppImage, and creates a new release.
4.  The releases include `.zsync` files for efficient delta updates.

## Downloads

You can find the latest AppImage in the [Releases](https://github.com/your-username/antigravity-appimage/releases/latest) section.

## Credits

This project is based on the excellent work by [valicm/VSCode-AppImage](https://github.com/valicm/VSCode-AppImage).

## Disclaimer

**This is an unofficial community project.** This repository and its maintainers are **not** affiliated, associated, authorized, endorsed by, or in any way officially connected with **Google LLC**, or any of its subsidiaries or its affiliates. The official Google website can be found at [https://google.com](https://google.com).

"Google" and "Antigravity" are trademarks of Google LLC.

## Naming Convention

The AppImage is named `Antigravity-x86_64.AppImage` to maintain compatibility with automatic update tools and consistent naming patterns.
