# 💸 Expense Tracker — Personal Expense Tracker App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13.4-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/SQLite-Sqflite%202.4-003B57?logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/State-Provider%206.1-6C5CE7" alt="Provider" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20iOS-2ecc71" alt="Platform" />
  <img src="https://img.shields.io/badge/Status-Completed-success" alt="Status" />
</p>

A modern **Personal Expense Tracker** application built with Flutter that allows users to manage daily income and expenses with real-time balance calculations, local SQLite persistence (`sqflite`), interactive charts, transaction categorization, and dynamic color coding.

---

## 📋 Assignment Requirements & Implementation Status

| Feature / Module | Requirement Details | Status | Implementation Details |
| :--- | :--- | :---: | :--- |
| **Dashboard Screen** | Display application name `Expense Tracker` | ✅ | Prominently displayed in the Dashboard header. |
| | Show 3 summary cards: `Total Income`, `Total Expense`, `Current Balance` | ✅ | Dynamically calculated real-time financial summary cards. |
| | Display a list of recent transactions | ✅ | Scrollable recent transactions list with dynamic sorting. |
| | Floating Action Button (FAB) to add transaction | ✅ | Prominent `+` FAB opening transaction form. |
| **Add Transaction** | Form with Title (`TextField`), Amount (`TextField`) | ✅ | Validated input fields (non-empty title, positive amount). |
| | Category (`DropdownButton`) | ✅ | `DropdownButtonFormField` with categories & selection validation. |
| | Transaction Type (`Income` / `Expense`) | ✅ | Selection between Income and Expense. |
| | Date (`DatePicker`) | ✅ | Interactive Material DatePicker (`showDatePicker`). |
| | Save Button & Validation | ✅ | Validates all required fields before saving to SQLite database. |
| **Transaction List** | Display all transactions using `ListView.builder` | ✅ | Built using `ListView.builder` with smooth scrolling. |
| | Display Title, Amount, Category, Date, Type badge | ✅ | Shows all 5 attributes clearly on each card. |
| | Distinct colors for Income (+) and Expenses (-) | ✅ | Green (`#00B894`) for Income, Red (`#FF6B6B`) for Expense. |
| **Update Transaction** | Edit existing transactions | ✅ | Dedicated edit screen pre-filling previous saved values. |
| | Open edit screen when a transaction is selected | ✅ | Opens `EditTransactionScreen` with editable fields. |
| | Save updated information in local database | ✅ | Persists updates to SQLite `transactions` table. |
| **Delete Transaction** | Delete any transaction | ✅ | Supported via swipe action and details view. |
| | **Display an `AlertDialog` before deleting** | ✅ | Prompts user with "Cancel" and "Delete" confirmation. |
| | Dynamic updates after deletion | ✅ | Automatically updates transaction list & dashboard cards. |
| **Transaction Details** | Complete transaction information on selection | ✅ | Shows Title, Amount, Category, Date & Time, Type, Note, ID. |
| | Provide Edit and Delete options | ✅ | Dedicated Edit and Delete buttons on the details screen. |
| **Local Database** | Store transactions locally using `sqflite` | ✅ | Database `expense_tracker.db` with table `transactions`. |
| | Table Structure | ✅ | `id INTEGER PRIMARY KEY AUTOINCREMENT`, `title TEXT`, `amount REAL`, `category TEXT`, `type TEXT`, `date TEXT`. |
| | Data persistence across app restarts | ✅ | All data remains available after closing & reopening the app. |

---

## 📱 Output Screens

<div align="center">

### 🚀 Splash & Dashboard
| Splash Screen | Dashboard / Home Page |
|:---:|:---:|
| <img src="lib/Output screens/Splash Screen.png" width="310" alt="Splash Screen" /> | <img src="lib/Output screens/Home Page.png" width="310" alt="Dashboard Screen" /> |

<br/>

### ➕ Add & Details
| Add Transaction Form | Transaction Details |
|:---:|:---:|
| <img src="lib/Output screens/add expense.png" width="310" alt="Add Expense Screen" /> | <img src="lib/Output screens/Expense details.png" width="310" alt="Expense Details Screen" /> |

<br/>

### 🗑️ Delete Dialog & Date Filter
| Delete Confirmation Dialog | Transactions by Date Filter |
|:---:|:---:|
| <img src="lib/Output screens/delete dialoge.png" width="310" alt="Delete Confirmation Dialog" /> | <img src="lib/Output screens/all transaction on a date.png" width="310" alt="All Transactions on a Date" /> |

</div>

---

## ✨ Key Features

- **📊 Dynamic Financial Summary**: Instant dynamic calculation of **Current Balance**, **Total Income**, and **Total Expense**.
- **🗄️ SQLite Offline Database (`sqflite`)**: Completely offline-first architecture storing all records in `expense_tracker.db` under table `transactions`.
- **🔄 Full CRUD Lifecycle**: Seamlessly Create, Read, Update, and Delete transactions with instant UI state synchronization.
- **🛡️ Delete Confirmation**: Safeguards transactions against accidental deletions using an intuitive `AlertDialog`.
- **🎯 Smart Filtering & Search**: Search expenses by title, category, or filter by specific date ranges.
- **🎨 Category Customization**: Rich category picker with personalized icons and consistent fintech color palettes.
- **🌓 Dark & Light Mode**: Seamless theme switching with high contrast and smooth transitions.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Channel stable, Material 3)
- **Language**: [Dart](https://dart.dev)
- **Local Database**: [`sqflite`](https://pub.dev/packages/sqflite) with [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) & [`path`](https://pub.dev/packages/path)
- **State Management**: [`provider`](https://pub.dev/packages/provider)
- **UI Components & Charts**: [`fl_chart`](https://pub.dev/packages/fl_chart), [`flutter_slidable`](https://pub.dev/packages/flutter_slidable), [`google_fonts`](https://pub.dev/packages/google_fonts)
- **Formatting**: [`intl`](https://pub.dev/packages/intl)

---

## 📂 Project Architecture

```
lib/
├── core/
│   ├── config.dart                 # Environment configuration (no secrets hardcoded)
│   └── constants.dart              # Global constants and limit types
├── models/
│   ├── category.dart               # Expense category data model
│   └── expense.dart                # Transaction model with toMap() / fromMap()
├── providers/
│   ├── expense_provider.dart       # Core transaction business logic & state
│   ├── budget_provider.dart        # Spending limits & budget state
│   ├── theme_provider.dart         # Theme switching (Light / Dark)
│   └── search_provider.dart        # Search & filtering state
├── screens/
│   ├── home_screen.dart            # Main Dashboard with summary cards & list
│   ├── dashboard_screen.dart       # Stats & visual analytics
│   ├── transaction_details_screen.dart # Detailed transaction view with Edit/Delete
│   ├── edit_transaction_screen.dart# Pre-filled form to update transactions
│   ├── budget_screen.dart          # Budget & spending limits screen
│   ├── limit_settings_screen.dart  # Limit configuration screen
│   ├── settings_screen.dart        # App preferences & categories
│   └── splash_screen.dart          # Launch screen navigating to Dashboard
├── services/
│   ├── database_helper.dart        # SQLite helper for expense_tracker.db
│   └── hive_service.dart           # Offline cache & preferences helper
├── theme/
│   ├── app_colors.dart             # Fintech color palette
│   └── app_theme.dart              # Light & Dark ThemeData
├── utils/
│   ├── formatters.dart             # Currency and date formatters
│   └── extensions.dart             # DateTime extension helpers
├── widgets/
│   ├── add_expense_sheet.dart      # Add transaction modal form
│   ├── dashboard_summary.dart      # 3 Summary cards widget
│   ├── expense_card.dart           # Reusable transaction card with swipe-to-delete
│   └── empty_state.dart            # Clean empty state widget
└── main.dart                       # App entry point
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `^3.6.0` or higher)
- Android Studio / VS Code with Flutter extension
- Android Device / Emulator or Windows Desktop

### 1. Clone the repository
```bash
git clone https://github.com/your-username/expense_tracker.git
cd expense_tracker
```

### 2. Environment Setup (Optional)
Copy `.env.example` to `.env` if using external services:
```bash
cp .env.example .env
```
*(The application works 100% offline using SQLite without requiring any API keys).*

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the Application
- **On Android**:
  ```bash
  flutter run -d android
  ```
- **On Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

### 5. Run Automated Tests
```bash
flutter test
```
*(Runs all unit tests for SQLite database helper, data models, and UI summary cards).*

---

## 🔒 Security & Privacy

- All sensitive API keys and secrets have been removed from frontend source code and migrated to environment variables.
- Local SQLite database files (`*.db`, `*.sqlite`) and `.env` files are ignored via `.gitignore` to prevent leaking private credentials or user data.

---

## 👤 Author

Developed as an assignment project for **Personal Expense Tracker App**.
