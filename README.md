# TT5 for Twitch

An iOS app that reads Twitch chat aloud with text-to-speech, so streamers and viewers can
follow chat through an earpiece or speaker instead of reading the screen.

Available on the [App Store](https://apps.apple.com/app/id6739819286).

## Features

- No login required: the channel view and chat reading are anonymous
- No data collection
- Background mode: the stream preview runs picture-in-picture, so you can use other apps
  (for example PRISM Live) or lock the phone
- All languages and voices supported by Apple's text-to-speech, with automatic language detection
- Speech settings for the whole app or per nick: voice, volume, rate, pitch, pronunciation
- Mute or unmute by role (moderators, VIPs, subscribers, channel owner), per nick,
  for highlighted messages, or for conversations
- Custom reward announcements with alert sounds
- Banned words, detected even when misspelled, using on-device speech recognition
- Skips links, chat bot commands and excessive emoji
- Profiles: save and load all settings to iOS Files

## Building

Requirements: Xcode 26 or later, iOS 17.2 or later.

1. Clone the repository and open `TT5.xcodeproj`.
2. To run in the simulator, nothing else is needed: just build and run.
3. To run on a device, create your personal build settings. This file is not under version control:

   ```sh
   cp User.template.xcconfig Config/User.xcconfig
   ```

   Then set `DEVELOPMENT_TEAM` (your Team ID from https://developer.apple.com/account)
   and a unique `BASE_PRODUCT_BUNDLE_IDENTIFIER`.

The repository contains placeholder artwork. The App Store app icon, logo and chat role badges
are not part of the repository: they live in local `*Store` asset sets, which are used when
present. In `Config/User.xcconfig`, `APP_ICON` selects the app icon set and `LAUNCH_SCREEN`
selects the launch screen storyboard.

## Dependencies

- [TwitchIRC](https://github.com/MahdiBM/TwitchIRC) for parsing Twitch chat messages

## Support

- Email: hilxenn@gmail.com
- Telegram: [t.me/hilxen](https://t.me/hilxen)
- Twitch: [twitch.tv/hilxen](https://www.twitch.tv/hilxen)

## License

[MIT](LICENSE)
