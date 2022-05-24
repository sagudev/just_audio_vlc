# just_audio_vlc

The [vlc](https://github.com/alexmercerind/dart_vlc) implementation of [`just_audio`](https://github.com/ryanheise/just_audio).

This project was based on this works:

- [GZGavinZhao/just_audio](https://github.com/GZGavinZhao/just_audio)
- [bdlukaa/just_audio_libwinmedia](https://github.com/bdlukaa/just_audio_libwinmedia)

This library would not be possible without [alexmercerind/dart_vlc](https://github.com/alexmercerind/dart_vlc)

Check out this repo for features table: [sagudev/just_audio](https://github.com/sagudev/just_audio/tree/vlc/just_audio)

## Installation

Add the [just_audio_vlc](https://pub.dev/packages/just_audio_libwinmedia) dependency to your `pubspec.yaml` alongside with `just_audio`:

```yaml
dependencies:
  just_audio: any # substitute version number
  just_audio_vlc: any # substitute version number
```

### Windows

Everything is already set up.

### macOS

To run on macOS, install CMake through [Homebrew](https://brew.sh):

```bash
brew install cmake
```

If you encounter the error `cmake: command not found` during archiving:

1. Download [CMake](https://cmake.org/download/) and move it to the `Applications` Folder.
2. Run:

```bash
sudo "/Applications/CMake.app/Contents/bin/cmake-gui" --install
```

### Linux

For using this plugin on Linux, you must have [VLC](https://www.videolan.org) & [libVLC](https://www.videolan.org/vlc/libvlc.html) installed.

**On Ubuntu/Debian:**

```bash
sudo apt-get install vlc
```

```bash
sudo apt-get install libvlc-dev
```

**On Fedora:**

```bash
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
```

```bash
sudo dnf install vlc
```

```bash
sudo dnf install vlc-devel
```
