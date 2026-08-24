# 🏏 Kricket.pk Mobile App

[![Flutter](https://img.shields.io/badge/Flutter->=3.3.0-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart->=3.3.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)](https://flutter.dev)

A modern, high-performance Flutter mobile application for **Kricket.pk**, delivering comprehensive coverage of Pakistani and international cricket. The app features live match updates, news articles, detailed tournament tracking, player career statistics, and complete domain entities (Regions, Clubs, Franchises, Departments, and Grounds).

---

## 📱 Features

- **🏠 Home Dashboard**: Clean, responsive feed showcasing breaking news, featured matches, and quick navigation.
- **📰 News & Articles**: Latest news feed with full article reader views and rich formatting.
- **🏏 Matches & Scorecards**: Live match tracking, upcoming fixtures, match results, detailed scorecards, ball-by-ball commentary, and head-to-head statistics.
- **🏆 Tournaments Hub**: In-depth coverage of domestic and international tournaments, including points tables, fixtures, top run-scorers, top wicket-takers, and squad listings.
- **👤 Players Directory**: Comprehensive database of player profiles, career statistics (Batting/Bowling across formats), recent form, and team affiliations.
- **🏢 Comprehensive Entity Detail Screens**: Dedicated detail screens for:
  - **Regions**, **Cities**, **Districts**
  - **Clubs**, **Franchises**, **Departments**
  - **Grounds**, **Countries**, **Teams**

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

