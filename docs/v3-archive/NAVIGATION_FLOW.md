# Navigation Flow Diagram

## App Structure

```
┌─────────────────────────────────────────┐
│      ChecklistListView (Main)           │
│  ┌─────────────────────────────────┐   │
│  │  [👤]         Checklists    [+]  │   │  ← Profile icon added here
│  └─────────────────────────────────┘   │
│                                         │
│  [Category Filters: All | Work | ...]  │
│                                         │
│  • Checklist 1            2/5          │
│  • Checklist 2            0/3          │
│  • Checklist 3            5/5 ✓       │
└─────────────────────────────────────────┘
           │
           │ Tap 👤
           ▼
┌─────────────────────────────────────────┐
│         ProfileView (Sheet)              │
│  ┌─────────────────────────────────┐   │
│  │  [Done]         Profile          │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌────────────────────────────────┐   │
│  │  👤  Welcome                    │   │
│  │      ✓ Premium / 🔘 Free Plan  │   │
│  └────────────────────────────────┘   │
│                                         │
│  Subscription                           │
│  • 👑 Plan                   [>]       │
│                                         │
│  Help & Support                         │
│  • ▶️ Tutorial               [>]       │
│  • ❓ Help & Support         [>]       │
│                                         │
│  About                                  │
│  • ℹ️ About                  [>]       │
│                                         │
│  Version 1.0 (1)                       │
└─────────────────────────────────────────┘
     │        │         │         │
     │        │         │         └──────────┐
     │        │         └──────────┐         │
     │        └──────────┐         │         │
     ▼                   ▼         ▼         ▼
┌──────────┐   ┌──────────┐   ┌─────┐   ┌───────┐
│PlanView  │   │Tutorial  │   │Help │   │About  │
│(Sheet)   │   │View      │   │View │   │View   │
└──────────┘   │(Sheet)   │   │(S)  │   │(S)    │
               └──────────┘   └─────┘   └───────┘
```

## Detailed View Breakdowns

### 1. PlanView
```
┌─────────────────────────────────────────┐
│  [Done]            Plan                  │
├─────────────────────────────────────────┤
│                                         │
│         ✓ Premium Plan                  │
│    You have access to all features      │
│                                         │
│  What's Included                        │
│  ┌─────────────────────────────────┐  │
│  │ ✓ Checklists  Free:1  Premium:∞│  │
│  │ ✓ Tags        Free:3  Premium:∞│  │
│  │ ✓ Categories  Free:3  Premium:∞│  │
│  │ ✓ iCloud Sync Free:—  Soon     │  │
│  └─────────────────────────────────┘  │
│                                         │
│  [If Free Plan: Purchase Buttons]       │
│  [If Premium: Manage Subscription]      │
│                                         │
└─────────────────────────────────────────┘
```

### 2. TutorialView
```
┌─────────────────────────────────────────┐
│  [Skip]         Tutorial                │
├─────────────────────────────────────────┤
│                                         │
│           ● ○ ○ ○ ○ ○                  │  ← Page indicators
│                                         │
│         ┌─────────────────┐            │
│         │   📋 [Icon]     │            │
│         └─────────────────┘            │
│                                         │
│       Create Checklists                 │
│                                         │
│   Tap the + button to create a         │
│   new checklist. Give it a name        │
│   and start adding items.              │
│                                         │
│                                         │
│                                         │
│  [Back]                    [Next]       │
└─────────────────────────────────────────┘
        Swipe left/right to navigate
```

### 3. HelpView
```
┌─────────────────────────────────────────┐
│  [Done]      Help & Support             │
├─────────────────────────────────────────┤
│  Quick Tips                             │
│  • Creating Checklists                  │
│    Tap the + button to create...       │
│  • Using Tags                           │
│    Organize items with tags...         │
│  • Categories                           │
│    Group checklists into...            │
│                                         │
│  Get in Touch                           │
│  • ✉️ Email Support         [>]        │
│    support@checklistapp.com            │
│  • 🌐 Visit Website         [↗]        │
│    www.checklistapp.com                │
│                                         │
│  Frequently Asked Questions             │
│  ▼ What's included in free?            │
│    The free plan includes...           │
│  > How do I cancel?                    │
│  > Is my data private?                 │
│  > How do I duplicate?                 │
└─────────────────────────────────────────┘
```

### 4. AboutView
```
┌─────────────────────────────────────────┐
│  [Done]            About                │
├─────────────────────────────────────────┤
│                                         │
│         ✓ [App Icon]                   │
│                                         │
│          Checklist                      │
│       Version 1.0 (1)                   │
│                                         │
│  Our Story                              │
│  Checklist was born from a simple      │
│  idea: staying organized shouldn't     │
│  be complicated...                     │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ 🔒 Privacy First                │  │
│  │ Your data stays on your device  │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ 🎨 Beautifully Simple           │  │
│  │ Powerful tools, easy to use     │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ ❤️ Made with Care               │  │
│  │ Built by a team who cares       │  │
│  └─────────────────────────────────┘  │
│                                         │
│     Made with ❤️ in 2026               │
│     © 2026 Checklist App               │
└─────────────────────────────────────────┘
```

## Interaction Patterns

### Sheet Presentation
All new screens use sheet presentation:
- Swipe down or tap "Done" to dismiss
- Maintains context of previous screen
- Clear visual hierarchy

### Navigation Hierarchy
```
Main App (ChecklistListView)
  └─ Profile (Sheet)
       ├─ Plan (Sheet on Sheet)
       ├─ Tutorial (Sheet on Sheet)
       ├─ Help (Sheet on Sheet)
       └─ About (Sheet on Sheet)
```

### Button Types
- **Primary Actions**: Colored accent buttons (purchases, Get Started)
- **Secondary Actions**: Gray/material background (Back, Cancel)
- **Navigation**: Chevron indicators (>)
- **External Links**: Arrow indicators (↗)
- **Dismissal**: "Done" text buttons

## Design System

### Colors
- **Primary**: System accent color (blue by default)
- **Success**: Green (for premium status, checkmarks)
- **Secondary**: System gray
- **Destructive**: System red (not used in these screens)

### Typography
- **Large Title**: Main screen titles
- **Title**: Section headers
- **Headline**: Feature titles
- **Subheadline**: Descriptions
- **Caption**: Secondary info

### Spacing
- **Section padding**: 16-32pt
- **Item spacing**: 8-16pt
- **Icon size**: 24-32pt for features
- **Large icons**: 56-80pt for headers

### Icons
All icons use SF Symbols:
- Profile: `person.crop.circle`
- Premium: `crown.fill`, `checkmark.seal.fill`
- Tutorial: `play.circle.fill`
- Help: `questionmark.circle.fill`
- About: `info.circle.fill`
- Email: `envelope.fill`
- Web: `globe`

## State Management

### Environment Objects
```swift
@EnvironmentObject var entitlementManager: EntitlementManager
@EnvironmentObject var storeKit: StoreKitManager
```

### State Properties
- `@State private var showProfile`: Controls profile sheet
- `@State private var showPlanView`: Controls plan sheet
- `@State private var showTutorial`: Controls tutorial sheet
- `@State private var showHelpView`: Controls help sheet
- `@State private var showAboutView`: Controls about sheet
- `@State private var currentPage`: Tutorial page index

## Localization Ready

All strings are ready for localization:
- Use `NSLocalizedString` for production
- Currently using inline English strings
- No hardcoded measurements (using system spacing)
- RTL layout support via SwiftUI default behavior
