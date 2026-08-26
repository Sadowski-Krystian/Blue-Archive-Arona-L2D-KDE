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
  <a href="https://github.com/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma">
    <!-- Jeśli masz logo, podmień link niżej. Jeśli nie, możesz na razie usunąć ten tag <img> -->
    <!-- <img src="images/logo.png" alt="Logo" width="80" height="80"> -->
  </a>

  <h3 align="center">Blue Archive L2D - Interactive Arona & Plana Wallpaper (KDE Plasma)</h3>

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
    <img src="https://count.getloli.com/@Sadowski-Krystian-Blue-Archive-Wallpaper?name=Sadowski-Krystian-Blue-Archive-Wallpaper&theme=original-new&padding=7&offset=0&align=center&scale=1&pixelated=1&darkmode=0" height="100" alt="Moe Counter">
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
- **Ultra Low Footprint:** Highly optimized memory and near-zero idle CPU usage.

---
<p align="right">(<a href="#readme-top">back to top</a>)</p> 

## 🛠️ Requirements & Dependencies

### Fedora / Bazzite / RHEL
```bash
sudo dnf install -y gcc-c++ cmake extra-cmake-modules \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtmultimedia-devel \
    kf6-plasma-devel kf6-kcoreaddons-devel
```

### Arch Linux / Manjaro
```bash
sudo pacman -S --needed base-devel cmake extra-cmake-modules \
    qt6-base qt6-declarative qt6-multimedia \
    plasma-workspace kcoreaddons
```

### Ubuntu / Debian / KDE Neon
```bash
sudo apt install -y build-essential cmake extra-cmake-modules \
    qt6-base-dev qt6-declarative-dev qt6-multimedia-dev \
    libkf6plasma-dev libkf6coreaddons-dev
```

---

<p align="right">(<a href="#readme-top">back to top</a>)</p> 

## 🔨 Building & Installation

### 1. Clone the repository with submodules
```bash
git clone --recursive add when published
cd Blue-Archive-Arona-Wallpaper-KDE
```

### 2. Build and install the plugin

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

### 3. Link/Install the Plasma Wallpaper Package
```bash
mkdir -p ~/.local/share/plasma/wallpapers/
ln -sf "$PWD/package" ~/.local/share/plasma/wallpapers/org.kde.plasma.bluearchive.arona
```

### 4. Activate the Wallpaper

1. Right-click your desktop $\rightarrow$ Configure Desktop and Wallpaper...
2. In Wallpaper Type, select Blue Archive Interactive Arona.

---

<p align="right">(<a href="#readme-top">back to top</a>)</p> 


## Intellectual Property & Exceptions

⚠️ **GAME ASSETS & IP EXCEPTION:** The GPL-3.0 license **DOES NOT** apply to the proprietary game assets, animation data, and character designs:

- **Blue Archive Assets:** Character designs (Arona, Plana), Spine 2D skeletons, sprite sheets, and audio files are the intellectual property of **NEXON Games Co.**, **Ltd.** and **Yostar, Inc.**
- **Spine Runtimes:** The src/spine-runtimes directory belongs to **Esoteric Software LLC** and is governed by the Spine Runtimes License Agreement.

<p align="right">(<a href="#readme-top">back to top</a>)</p> 



<!-- CHANGE ALL WHEN PUBLISHED -->
<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma.svg?style=for-the-badge
[contributors-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma.svg?style=for-the-badge
[forks-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma/network/members
[stars-shield]: https://img.shields.io/github/stars/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma.svg?style=for-the-badge
[stars-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma/stargazers
[issues-shield]: https://img.shields.io/github/issues/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma.svg?style=for-the-badge
[issues-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma/issues
[license-shield]: https://img.shields.io/badge/License-GPL_3.0-blue.svg?style=for-the-badge
[license-url]: https://github.com/Sadowski-Krystian/Blue-Archive-Theme-KDE-Plasma/blob/main/LICENSE

<!-- Badges dla technologii -->
[KDE-shield]: https://img.shields.io/badge/KDE-%231D99F3.svg?style=for-the-badge&logo=kde&logoColor=white
[KDE-url]: https://kde.org/

<!-- Copyrights -->

[COPYRIGHT-LOCK-ARTIST]: https://www.pixiv.net/en/users/16710545
[COPYRIGHT-LOCK-SOURCE]: https://www.pixiv.net/en/artworks/115226775
[COPYRIGHT-DESKTOP-ARTIST]: https://www.pixiv.net/en/users/72896190
[COPYRIGHT-DESKTOP-SOURCE]: https://www.pixiv.net/en/artworks/111576669
[STEAM-STARTUP]: https://shared.fastly.steamstatic.com/community_assets/images/items/3557620/5/movie_large/7b6e3a5b503f415b6323e4295edfb645.webm
[ARONA-SPLASH]: https://github.com/Machillka/arona-splash-theme
[PLYMOUTH-WALLPAPER]: https://moewalls.com/anime/arona-in-classroom-blue-archive-live-wallpaper/
