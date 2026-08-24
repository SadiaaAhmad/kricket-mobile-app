# 🏏 Kricket.pk Mobile App

[![Flutter](https://img.shields.io/badge/Flutter->=3.3.0-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart->=3.3.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)](https://flutter.dev)

A modern, high-performance Flutter mobile application for **Kricket.pk**, delivering comprehensive coverage of Pakistani and international cricket. The app features live match updates, news articles, detailed tournament tracking, player career statistics, and complete domain entities (Regions, Clubs, Franchises, Departments, and Grounds).

---

## 📱 Features

- **🏠 Home Dashboard**: Clean, responsive feed showcasing breaking news, featured matches, and quick navigation.
  <img width="300" height="598" alt="image" src="https://github.com/user-attachments/assets/c2e482d2-4086-43b4-b751-51b951df310d" /><img width="298" height="595" alt="image" src="https://github.com/user-attachments/assets/dd9ec28c-2e27-41ee-ba3c-a453c724bccd" />

- **📰 News & Articles**: Latest news feed with full article reader views and rich formatting.
  <img width="300" height="595" alt="image" src="https://github.com/user-attachments/assets/e8e77378-e66e-4787-a769-4c853f6b0b9e" />

- **🏏 Matches & Scorecards**: Live match tracking, upcoming fixtures, match results, detailed scorecards, ball-by-ball commentary, and head-to-head statistics.
  <img width="300" height="600" alt="image" src="https://github.com/user-attachments/assets/8a0c38c7-00a1-479f-afcb-0a4d85b3cbbb" /><img width="300" height="597" alt="image" src="https://github.com/user-attachments/assets/8d171eb4-1bdc-4166-9410-94637dcd5271" />

- **🏆 Tournaments Hub**: In-depth coverage of domestic and international tournaments, including points tables, fixtures, top run-scorers, top wicket-takers, and squad listings.
  <img width="300" height="596" alt="image" src="https://github.com/user-attachments/assets/0bc23ab2-513b-45f2-9fbc-b785f169b306" />

- **👤 Players Directory**: Comprehensive database of player profiles, career statistics (Batting/Bowling across formats), recent form, and team affiliations.
  <img width="298" height="596" alt="image" src="https://github.com/user-attachments/assets/935d605b-9ef0-41b4-917e-fa3ba75af13e" />

- **🏢 Comprehensive Entity Detail Screens**: Dedicated detail screens for:
  - **Regions**, **Cities**, **Districts**
  - **Clubs**, **Franchises**, **Departments**
  - **Grounds**, **Countries**, **Teams**
    <img width="300" height="600" alt="image" src="https://github.com/user-attachments/assets/f4ff5c08-4366-4d57-9200-5c0603dfe310" /><img width="298" height="597" alt="image" src="https://github.com/user-attachments/assets/a4467f2b-73ba-4508-866c-db15073b078f" /><img width="300" height="593" alt="image" src="https://github.com/user-attachments/assets/b2fb3850-2669-4ae0-8d2d-90857fb27cc2" />
    
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

