# 🍽️ RecipeMate — Intelligent Mobile Recipe Application

> A smart Flutter mobile app that recommends personalized recipes, manages your pantry, and supports your nutrition goals through AI.

---

## 📌 Overview

**RecipeMate** is a cross-platform mobile application built with **Flutter** that helps users explore thousands of recipes, organize their favorites, manage their pantry, and receive AI-powered personalized meal recommendations — all tailored to their diet, allergies, and health goals.

### The Problem It Solves

Users struggle to find recipes suited to their diet, track what they have at home, and avoid food waste. RecipeMate addresses all three by combining a rich recipe database, a smart pantry manager, and an AI recommendation engine in one place.

---

## ✨ Features

### 🔐 Authentication & Onboarding
- Landing, Login, and Sign Up pages
- 4-step onboarding to personalize the experience:
  - Health goal selection
  - Allergy management
  - Diet type preference
  - Cooking experience level

### 🏠 Home Page
- Category filters (Lunch, Breakfast, Dinner, etc.)
- Allergy-aware filtering
- **AI Mode** — personalized recipe suggestions powered by Google Gemini
- Search by recipe name
- Popular recipes section

### 📖 Recipe Detail Page
- Recipe image, name, category & origin
- Calories & macronutrients breakdown
- Nutrition pie chart
- Ingredients list with images
- Step-by-step instructions
- YouTube video link
- Allergy warnings

### ❤️ Favorites Page
- Grid display of saved recipes
- Add / remove favorites
- Real-time sync with Firestore

### 🥦 Pantry Page
- Add, edit, and delete ingredients
- Search within pantry

### 👤 Profile Page
- View and update profile
- Change profile picture (via ImgBB)
- Update health goals and manage allergies

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart) |
| **Authentication** | Firebase Authentication |
| **Database** | Cloud Firestore (real-time NoSQL) |
| **Recipe Data** | TheMealDB API |
| **AI Recommendations** | Google Gemini API |
| **Image Uploads** | ImgBB API |

---

## 🏗️ Architecture

The app follows a clean **3-layer architecture**:

```
┌─────────────────────────────────────┐
│      Presentation Layer (UI)         │
│  Flutter pages · Material widgets    │
│  setState · Page navigation          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          Service Layer               │
│  RecipeService   → TheMealDB API     │
│  FavoritesService → Firestore        │
│  GeminiService   → AI recommendations│
│  ImgBBService    → Image uploads     │
│  DatabaseService → Firestore ops     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│           Data Layer                 │
│  Models: Recipe, Ingredient, Allergy │
│  Firebase Firestore collections:     │
│    - users · favorites · pantry      │
└─────────────────────────────────────┘
```

---

## 🗄️ Firestore Database Structure

```
Firestore
├── users/
│   └── {userId}
│       ├── name, email, profilePicture
│       ├── healthGoal, dietType, experienceLevel
│       └── allergies[]
│
├── favorites/
│   └── {userId}
│       └── {recipeId}
│           └── recipe data
│
└── pantry/
    └── {userId}
        └── {ingredientId}
            └── name, quantity, unit
```

---

## ⚙️ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or higher)
- Dart SDK
- Android Studio or VS Code with Flutter extension
- A Firebase project
- API keys for Google Gemini and ImgBB

### 1. Clone the repository

```bash
git clone https://github.com/your-username/recipemate.git
cd recipemate
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

1. Create a project at [Firebase Console](https://console.firebase.google.com/)
2. Enable **Authentication** (Email/Password)
3. Enable **Cloud Firestore**
4. Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS)
5. Place them in the appropriate directories:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

### 4. Configure API keys

Create a `lib/config/api_config.dart` file:

```dart
const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
const String imgbbApiKey  = 'YOUR_IMGBB_API_KEY';
// TheMealDB is free and requires no key
```

> ⚠️ Never commit API keys to version control. Add this file to your `.gitignore`.

### 5. Run the app

```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── config/
│   └── api_config.dart
├── models/
│   ├── recipe.dart
│   ├── ingredient.dart
│   └── allergy.dart
├── services/
│   ├── recipe_service.dart        # TheMealDB API
│   ├── favorites_service.dart     # Firestore favorites
│   ├── gemini_service.dart        # AI recommendations
│   ├── imgbb_service.dart         # Image uploads
│   └── database_service.dart     # Firestore operations
└── pages/
    ├── landing_page.dart
    ├── login_page.dart
    ├── signup_page.dart
    ├── onboarding/
    ├── home_page.dart
    ├── recipe_detail_page.dart
    ├── favorites_page.dart
    ├── pantry_page.dart
    └── profile_page.dart
```

---

## 👥 Team

| Name |
|---|
| Meriem Bejaoui |
| Ghada Fatnassi |
| Tasnim Hajjeji |

**Class:** DSI31

---

## 📄 License

This project was developed as an academic project. All rights reserved © 2026.
