# Contributing to TT5

Thanks for your interest in improving TT5!

## Questions, bugs and ideas

- Questions and ideas: [Discussions](https://github.com/hilxen/tt5/discussions)
- Bugs and feature requests: [Issues](https://github.com/hilxen/tt5/issues/new/choose)
- Security issues: see [SECURITY.md](SECURITY.md), please don't open a public issue

## Building

See [Building](README.md#building) in the README. In short: open `TT5.xcodeproj` and run in the
simulator. For a device, copy `User.template.xcconfig` to `Config/User.xcconfig` and set your
Team ID and bundle identifier. That file is not under version control, so never commit it.

The App Store icon, logo and role badges are not in the repository. The placeholder artwork is
used instead, so the app looks different from the App Store version. That is expected.

## Pull requests

1. For anything bigger than a small fix, open an issue or discussion first, so we can agree on
   the approach.
2. Keep each pull request focused on one change, and follow the style of the surrounding code.
3. Don't change `Config/Base.xcconfig` (version and build number) or the bundle identifier.
4. Test in the simulator or on a device, and describe how in the pull request.

Pull requests are squash merged. By contributing, you agree that your contribution is licensed
under the [MIT License](LICENSE).

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
