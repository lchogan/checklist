# Profile & Help Features - Implementation Guide

## Overview
This document describes the new profile, help, tutorial, and subscription management features added to the Checklist app.

## New Files Created

### 1. ProfileView.swift
**Purpose:** Main profile/settings screen accessible from the checklist list view

**Features:**
- Profile header showing premium status
- Navigation to Plan, Tutorial, Help, and About screens
- App version display
- Clean, organized list-based interface

**Access:** Tap the profile icon (person.crop.circle) in the top-left corner of the main checklist screen

### 2. PlanView.swift
**Purpose:** Subscription management and upgrade screen

**Features:**
- Displays current plan status (Free or Premium)
- Feature comparison table showing limits vs. premium benefits
- Purchase options for monthly and annual subscriptions
- "Manage Subscription" button for existing subscribers
- Integration with StoreKit for in-app purchases
- Restore purchases functionality

**Key Components:**
- `PlanFeatureRow`: Displays feature comparison (Free vs Premium)
- `PremiumPurchaseButton`: Styled button for subscription options

### 3. HelpView.swift
**Purpose:** Help and support center with FAQs and contact options

**Features:**
- Quick tips section with common help topics
- Email support integration (opens native mail composer)
- Website link (opens in Safari)
- Expandable FAQ section covering:
  - What's included in free version
  - How to cancel subscription
  - Data privacy information
  - How to duplicate checklists
- Device and app version information included in support emails

**Key Components:**
- `HelpTopicRow`: Displays help topics with icons
- `MailComposeView`: UIKit wrapper for mail composition

**Contact Details (Update These):**
- Support email: `support@checklistapp.com`
- Website: `https://www.checklistapp.com`

### 4. TutorialView.swift
**Purpose:** Interactive walkthrough teaching app features

**Features:**
- 6-page swipeable tutorial
- Page indicator dots
- Back/Next navigation
- Skip button to exit anytime
- Topics covered:
  1. Creating Checklists
  2. Checking Off Items
  3. Organizing with Tags
  4. Using Categories
  5. Duplicate & Share
  6. Premium Features

**Design:**
- Color-coded pages with themed icons
- Clear, concise descriptions
- "Get Started" button on final page

### 5. AboutView.swift
**Purpose:** Information about the app and its creators

**Features:**
- App icon and version display
- "Our Story" section with mission statement
- Core values cards:
  - Privacy First
  - Beautifully Simple
  - Made with Care
- Copyright information

**Customizable Content:**
- All text is placeholder and should be updated to reflect your actual story
- Copyright year set to 2026

## Updated Files

### ChecklistListView.swift
**Changes:**
- Added profile icon button in toolbar (top-left)
- Added `@State private var showProfile` property
- Added `.sheet(isPresented: $showProfile)` to present ProfileView

## Integration Requirements

### 1. StoreKit Configuration
The Plan screen integrates with your existing StoreKit setup:
- Uses `StoreKitManager` from environment
- Displays products from App Store Connect
- Handles purchases and restoration

**Product IDs** (already configured in StoreKitManager.swift):
- Monthly: `com.checklist.premium.monthly`
- Annual: `com.checklist.premium.annual`

### 2. Environment Objects Required
All new views require these environment objects:
```swift
.environmentObject(entitlementManager)
.environmentObject(storeKit)
```

These are already provided in `AppRoot`, so no additional setup is needed.

### 3. Mail Composer
The Help screen uses `MessageUI` for email composition:
- Automatically detects if Mail app is configured
- Shows alert if email is unavailable
- Includes device info in email body

### 4. Bundle Extension
Added extension to `Bundle` in ProfileView.swift:
```swift
var appVersion: String // Returns "1.0 (1)" format
```

## Customization Guide

### Update Contact Information
In **HelpView.swift**, change these constants:
```swift
private let supportEmail = "support@checklistapp.com"
private let websiteURL = "https://www.checklistapp.com"
```

### Update About Content
In **AboutView.swift**, edit the "Our Story" text and company information to match your brand.

### Customize Tutorial Content
In **TutorialView.swift**, modify the `pages` array to add, remove, or change tutorial steps.

### Change Color Scheme
Tutorial pages use color-coded themes. Modify the `color` property in each `TutorialPage` to match your brand colors.

## User Flow

### Main Flow
1. User taps profile icon in main checklist screen
2. ProfileView sheet appears
3. User can navigate to:
   - **Plan**: View/manage subscription
   - **Tutorial**: Learn how to use the app
   - **Help & Support**: Get help or contact support
   - **About**: Learn about the app

### Upgrade Flow
1. User taps "Plan" in profile
2. Sees feature comparison
3. Can purchase monthly or annual subscription
4. After purchase, returns to plan screen showing premium status

### First-Time User Flow
1. New user opens app
2. Taps profile icon
3. Taps "Tutorial"
4. Swipes through interactive walkthrough
5. Taps "Get Started" to begin using app

## Testing Checklist

- [ ] Profile icon appears in top-left of main screen
- [ ] Profile sheet opens when tapping icon
- [ ] All navigation buttons work in profile screen
- [ ] Plan screen shows correct free/premium status
- [ ] Purchase buttons work (test in sandbox environment)
- [ ] Restore purchases works
- [ ] Email composer opens (requires Mail configured)
- [ ] Website link opens in Safari
- [ ] Tutorial pages swipe correctly
- [ ] FAQ items expand/collapse
- [ ] About screen displays all content
- [ ] "Done" buttons dismiss sheets correctly

## Design Decisions

### Why Sheets Instead of Navigation?
All new screens use `.sheet()` presentation for these reasons:
- Clear entry/exit points
- Maintains context of main checklist view
- Matches iOS system settings patterns
- Easy to dismiss with swipe gesture

### Why Separate Views?
Each feature is a separate file for:
- Better code organization
- Easier maintenance
- Reusability
- Clearer separation of concerns

### Premium Badge
The profile header shows premium status prominently to:
- Encourage upgrades
- Provide clear status indication
- Create aspirational value

## Accessibility

All views include:
- Semantic labels for screen readers
- Sufficient tap targets (44pt minimum)
- Clear visual hierarchy
- Support for Dynamic Type
- Proper color contrast

## Future Enhancements

Potential additions:
- [ ] Add app settings (notifications, theme, etc.)
- [ ] Add rate/review app prompt
- [ ] Add referral/share feature
- [ ] Add tutorial video links
- [ ] Add in-app feedback mechanism
- [ ] Add changelog viewer
- [ ] Add export/import features

## Notes

- All placeholder text should be updated to match your brand
- Email and website URLs must be updated before release
- Tutorial content should be updated as app features evolve
- Consider adding analytics to track tutorial completion
- Consider first-launch tutorial prompt

## Support

For questions about this implementation, refer to:
- Apple's Human Interface Guidelines for iOS
- StoreKit 2 documentation
- SwiftUI documentation
