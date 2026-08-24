# 🏏 Kricket.pk Mobile App

[![Flutter](https://img.shields.io/badge/Flutter->=3.3.0-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart->=3.3.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)](https://flutter.dev)

A modern, high-performance Flutter mobile application for **Kricket.pk**, delivering comprehensive coverage of Pakistani and international cricket. The app features live match updates, news articles, detailed tournament tracking, player career statistics, and complete domain entities (Regions, Clubs, Franchises, Departments, and Grounds).

---

## 📱 Features

### 🏠 Home Dashboard

A clean and responsive dashboard that brings together the most important cricket content in one place, including breaking news, featured matches, quick navigation, and trending content.

<p align="center">
  <img src="https://github.com/user-attachments/assets/c2e482d2-4086-43b4-b751-51b951df310d" width="280" alt="Home Dashboard" />
  <img src="https://github.com/user-attachments/assets/dd9ec28c-2e27-41ee-ba3c-a453c724bccd" width="280" alt="Home Dashboard" />
</p>

---

### 📰 News & Articles

Stay updated with the latest cricket stories through a structured news feed and immersive article reader experience with rich content formatting.

<p align="center">
  <img src="https://github.com/user-attachments/assets/e8e77378-e66e-4787-a769-4c853f6b0b9e" width="280" alt="Cricket News and Article Detail" />
</p>

---

### 🏏 Matches & Scorecards

Track live matches, upcoming fixtures, and completed results with access to detailed match centres featuring scorecards, ball-by-ball commentary, and head-to-head statistics.

<p align="center">
  <img src="https://github.com/user-attachments/assets/8a0c38c7-00a1-479f-afcb-0a4d85b3cbbb" width="280" alt="Matches Overview" />
  <img src="https://github.com/user-attachments/assets/8d171eb4-1bdc-4166-9410-94637dcd5271" width="280" alt="Match Scorecard" />
</p>

---

### 🏆 Tournaments Hub

Explore domestic and international tournaments with detailed information including:

* 📊 Points tables
* 📅 Fixtures
* 🏏 Top run-scorers
* 🎯 Top wicket-takers
* 👥 Team squads

<p align="center">
  <img src="https://github.com/user-attachments/assets/0bc23ab2-513b-45f2-9fbc-b785f169b306" width="280" alt="Tournament Hub" />
</p>

---

### 👤 Players Directory

Browse a comprehensive directory of cricket players and explore detailed player profiles featuring career statistics, recent form, playing records, and team affiliations.

<p align="center">
  <img src="https://github.com/user-attachments/assets/935d605b-9ef0-41b4-917e-fa3ba75af13e" width="280" alt="Players Directory" />
</p>

---

### 🏢 Entity Detail Screens

Explore detailed information across the entire cricket ecosystem through dedicated entity screens.

**Supported entities include:**

| Category                | Entities                              |
| :---------------------- | :------------------------------------ |
| 📍 **Locations**        | Regions, Cities, Districts, Countries |
| 🏏 **Organizations**    | Clubs, Franchises, Departments        |
| 🌍 **Cricket Entities** | Grounds, Teams                        |

<p align="center">
  <img src="https://github.com/user-attachments/assets/f4ff5c08-4366-4d57-9200-5c0603dfe310" width="250" alt="Entity Detail Screen" />
  <img src="https://github.com/user-attachments/assets/a4467f2b-73ba-4508-866c-db15073b078f" width="250" alt="Entity Detail Screen" />
  <img src="https://github.com/user-attachments/assets/b2fb3850-2669-4ae0-8d2d-90857fb27cc2" width="250" alt="Entity Detail Screen" />
</p>

---

> Built as a Flutter-based mobile experience for **Kricket.pk**, bringing cricket news, live matches, tournaments, players, and detailed cricket statistics into a unified mobile application.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (SDK `>=3.3.0 <4.0.0`) with Material 3 UI design
- **Language**: [Dart](https://dart.dev)
- **Key Packages**:
  - `http`: REST API communication
  - `webview_flutter`: Embedded web content rendering
  - `url_launcher`: External link handling

### 📂 Directory Structure

```
lib/
├── constants/        # Centralized theme tokens (K.dark, K.green, K.lime), typography, & styles
├── data/             # Data repositories & curated datasets (articles, tournaments, raw mocks)
├── models/           # Strongly-typed Dart data models (Player, Match, Tournament, Article, etc.)
├── screens/          # App screens (Home, News, Matches, Tournaments, Players, & Entity Detail views)
├── services/         # Modular API service wrappers (News, Matches, Players, Tournaments)
├── widgets/          # Reusable UI components & custom navigation shell
└── main.dart         # Application entry point & root widget setup
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode / VS Code with Flutter extension

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/SadiaaAhmad/kricket-mobile-app.git
   cd kricket-mobile-app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

---

## 📄 License

This project is open-source. All rights reserved.

