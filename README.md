<a id="readme-top"></a>

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPL 3.0 License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE">
    <!-- Jeśli masz logo, podmień link niżej. Jeśli nie, możesz na razie usunąć ten tag <img> -->
    <!-- <img src="images/logo.png" alt="Logo" width="80" height="80"> -->
  </a>

  <h3 align="center">Blue Archive L2D - Interactive Arona & Plana Wallpaper (KDE Plasma)</h3>
  <h3>Made with 🩵 from Fan to Fans</h3> 
  <p align="center">
    A lightweight, native Qt Quick (C++ / Spine 2D) interactive wallpaper for KDE Plasma featuring Arona and Plana with in-game animations, touch reactions, and voice lines.
    <br />
    <br />
    <a href="https://github.com/Sadowski-Krystian/Blue-Archive-Arona-Wallpaper-KDE/issues">Report Bug</a>
    &middot;
    <a href="https://github.com/Sadowski-Krystian/Blue-Archive-Arona-Wallpaper-KDE/issues">Request Feature</a>
  </p>
</div>

<div align="center">
  <!-- Replace '@Sadowski-Krystian-Blue-Archive-Wallpaper' after registering on count.getloli.com -->
  <a href="https://count.getloli.com/">
    <img src="https://count.getloli.com/@Blue-Archive-Arona-L2D-KDE?name=Blue-Archive-Arona-L2D-KDE&theme=original-new&padding=7&offset=0&align=center&scale=1&pixelated=1&darkmode=0" height="100" alt="Moe Counter">
  </a>
</div>

<!-- ABOUT THE PROJECT -->

## ⚖️ License & Copyright

The original source code, scripts, and configuration files of this project are licensed under the GNU General Public License v3.0 (GPL-3.0). See the LICENSE file for details. This licence is not applied to [Intellectual Property & Exceptions](#intellectual-property--exceptions)

## 🌟 Features

- **Native C++ & Qt Quick Renderer:** Hardware-accelerated Spine 2D rendering directly on KDE Plasma's scene graph without heavy web-engine overhead.
- **Interactive Responses:** Tap and click reactions with real-time skeletal animations.
- **Voice Lines:** Official audio clips dynamically synchronized with character actions.
- **Character Switching:** Seamlessly toggle between **Arona** and **Plana**.
- **Day & Night Cycles:** Dynamic classroom backgrounds adjusting based on time of day.

---
<p align="right">(<a href="#readme-top">back to top</a>)</p> 

## 🛠️ Requirements & Dependencies

This wallpaper requires **KDE Plasma 6** and **Qt 6 Multimedia** (including GStreamer audio codecs for `.ogg` voice lines).

### Runtime Dependencies (Pre-built `.plasmoid`)

If you are using the pre-built release, you only need the runtime packages for your distribution:

* **Arch Linux / Manjaro:**
  ```bash
  sudo pacman -S qt6-multimedia gstreamer gst-plugins-good gst-plugins-bad
  ```
* **Fedora / RHEL (Fedora 40+):**
  ```bash
  sudo dnf install qt6-qtmultimedia gstreamer1-plugins-good gstreamer1-plugins-bad-free
  ```
* **openSUSE Tumbleweed:**
  ```bash
  sudo zypper install qt6-multimedia gstreamer-plugins-good gstreamer-plugins-bad
  ```
* **KDE Neon / Kubuntu (Plasma 6+):**
  ```bash
  sudo apt install qml6-module-qtmultimedia libqt6multimedia6 gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
  ```


### Build Dependencies (Compiling from Source)

If you intend to build the C++ plugin yourself instead of using the pre-built `.plasmoid`:

* **Arch Linux:**
  ```bash
  sudo pacman -S base-devel cmake extra-cmake-modules qt6-base qt6-declarative qt6-multimedia libplasma
  ```
* **Fedora:**
  ```bash
  sudo dnf install cmake gcc-c++ extra-cmake-modules qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtmultimedia-devel libplasma-devel kf6-ki18n-devel kf6-kcoreaddons-devel
  ```
* **openSUSE Tumbleweed:**
  ```bash
  sudo zypper install cmake gcc-c++ extra-cmake-modules qt6-base-devel qt6-declarative-devel qt6-multimedia-devel libplasma-devel
  ```


If there is problem with any package please open a <a href="https://github.com/Sadowski-Krystian/Blue-Archive-Arona-Wallpaper-KDE/issues">Report Bug</a>

---

<p align="right">(<a href="#readme-top">back to top</a>)</p> 

## 🔨 Installation

### Method 1: Installation script


```bash
curl -sSL https://raw.githubusercontent.com/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE/refs/heads/main/install.sh | bash
```

Remember to change your desktop `Layout` from `Folder View` to `Desktop`

### Method 2: Manual Install via Terminal

1. Download `l2d.arona.plana.bluearchive.plasmoid` from the <a href="https://github.com/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE/releases/tag/latest">release</a> tab.
2. Open your terminal in your `Downloads` directory and run:
```bash
kpackagetool6 --type Plasma/Wallpaper --install l2d.arona.plana.bluearchive.plasmoid
```
*(If updating from an earlier version, use `--upgrade` instead of `--install`).*

3. Change in your wallpaper settings from image to `Blue Archive Interactive Arona Wallpaper L2D` 
  
  Remember to change your desktop `Layout` from `Folder View` to `Desktop`

---

<p align="right">(<a href="#readme-top">back to top</a>)</p> 


## Intellectual Property & Exceptions

⚠️ **GAME ASSETS & IP EXCEPTION:** The GPL-3.0 license **DOES NOT** apply to the proprietary game assets, animation data, and character designs:

- **Blue Archive Assets:** Character designs (Arona, Plana), Spine 2D skeletons, sprite sheets, and audio files are the intellectual property of **NEXON Games Co.**, **Ltd.** and **Yostar, Inc.**
- **Spine Runtimes:** The src/spine-runtimes directory belongs to **Esoteric Software LLC** and is governed by the Spine Runtimes License Agreement.

<p align="right">(<a href="#readme-top">back to top</a>)</p> 



<!-- CHANGE ALL WHEN PUBLISHED -->
<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE.svg?style=for-the-badge
[contributors-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE.svg?style=for-the-badge
[forks-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE/network/members
[stars-shield]: https://img.shields.io/github/stars/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE.svg?style=for-the-badge
[stars-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE/stargazers
[issues-shield]: https://img.shields.io/github/issues/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE.svg?style=for-the-badge
[issues-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE/issues
[license-shield]: https://img.shields.io/badge/License-GPL_3.0-blue.svg?style=for-the-badge
[license-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE/blob/main/LICENSE

<!-- Badges dla technologii -->
[KDE-shield]: https://img.shields.io/badge/KDE-%231D99F3.svg?style=for-the-badge&logo=kde&logoColor=white
[KDE-url]: https://kde.org/
