# RevenueCat Setup Checklist for ZenJournal

This document describes how to configure RevenueCat for ZenJournal's subscription system.

---

## 1. RevenueCat Console Setup

### 1.1 Create a Project

1. Log in to [RevenueCat Dashboard](https://app.revenuecat.com/).
2. Click **Create New Project**.
3. Name it `ZenJournal`.

### 1.2 Add Apps

- **Apple App Store**: Add your iOS/macOS app and enter the App-Specific Shared Secret from App Store Connect.
- **Google Play Store**: Add your Android app and upload the Play Store service account JSON credentials.

---

## 2. Product IDs

Create the following products in both App Store Connect and Google Play Console:

| Product ID                | Type            | Price   | Description                        |
|---------------------------|-----------------|---------|------------------------------------|
| `zen_journal_monthly`     | Auto-renewable  | $4.99   | ZenJournal Pro Monthly             |
| `zen_journal_yearly`      | Auto-renewable  | $29.99  | ZenJournal Pro Yearly (40% off)    |
| `zen_journal_lifetime`    | Non-consumable  | $79.99  | ZenJournal Pro Lifetime            |

---

## 3. App Store Connect Configuration

### 3.1 Create Subscription Group

1. Go to **App Store Connect > Your App > Subscriptions**.
2. Create a subscription group named `ZenJournal Pro`.
3. Add two subscriptions:
   - **zen_journal_monthly**: Duration = 1 Month, Price = $4.99
   - **zen_journal_yearly**: Duration = 1 Year, Price = $29.99
4. Set up a **7-day free trial** for both subscriptions under Subscription Prices > Introductory Offers.

### 3.2 Create Non-Consumable (Lifetime)

1. Go to **In-App Purchases**.
2. Create a non-consumable product:
   - Product ID: `zen_journal_lifetime`
   - Reference Name: ZenJournal Pro Lifetime
   - Price: $79.99

### 3.3 Get Shared Secret

1. Go to **App Store Connect > Your App > General > App-Specific Shared Secret**.
2. Copy the secret and enter it in RevenueCat Dashboard under your Apple app settings.

---

## 4. Google Play Console Configuration

### 4.1 Create Subscriptions

1. Go to **Google Play Console > Your App > Monetize > Products > Subscriptions**.
2. Create a subscription with ID `zen_journal_pro`.
3. Add two base plans:
   - **monthly**: Billing period = 1 Month, Price = $4.99, Product ID tag = `zen_journal_monthly`
   - **yearly**: Billing period = 1 Year, Price = $29.99, Product ID tag = `zen_journal_yearly`
4. For each base plan, add a **7-day free trial** offer.

### 4.2 Create One-Time Product (Lifetime)

1. Go to **Products > In-app products**.
2. Create a product:
   - Product ID: `zen_journal_lifetime`
   - Price: $79.99

### 4.3 Service Account Setup

1. Go to **Google Play Console > Settings > API Access**.
2. Create or link a service account.
3. Grant the service account **Financial Data** permissions.
4. Download the JSON key and upload it to RevenueCat.

---

## 5. RevenueCat Entitlement & Offering

### 5.1 Create Entitlement

1. In RevenueCat Dashboard, go to **Project Settings > Entitlements**.
2. Create an entitlement:
   - Identifier: `premium`
   - Description: Unlocks all ZenJournal Pro features.

### 5.2 Attach Products to Entitlement

1. Under the `premium` entitlement, click **Attach**.
2. Add all three products:
   - `zen_journal_monthly`
   - `zen_journal_yearly`
   - `zen_journal_lifetime`

### 5.3 Create Offering

1. Go to **Project Settings > Offerings**.
2. Create a new offering:
   - Identifier: `default` (this is the current offering used by the app)
3. Add three packages:
   - **$rc_monthly**: Attach `zen_journal_monthly`
   - **$rc_annual**: Attach `zen_journal_yearly`
   - **$rc_lifetime**: Attach `zen_journal_lifetime`
4. Mark this offering as **Current**.

---

## 6. Flutter SDK Integration

The app uses RevenueCat's Flutter SDK via `purchases_flutter`.

### 6.1 Initialization

RevenueCat is initialized in `core/subscription/subscription_provider.dart` via:

```dart
SubscriptionService.initialize(apiKey: 'YOUR_REVENUECAT_API_KEY');
```

Replace `YOUR_REVENUECAT_API_KEY` with:
- **Apple**: The public API key from RevenueCat > Project > Apple App.
- **Android**: The public API key from RevenueCat > Project > Google Play App.

Use `Platform.isIOS` to select the correct key at runtime.

### 6.2 Providers

- `offeringsProvider`: Fetches available offerings (used in the paywall).
- `customerInfoProvider`: Streams customer info updates for entitlement checks.
- `isPremiumProvider`: Derives boolean premium status from `customerInfoProvider`.
- `showAdsProvider`: Returns `true` if the user does NOT have premium (used for ad display).

---

## 7. Sandbox Testing

### 7.1 Apple Sandbox

1. Go to **App Store Connect > Users and Access > Sandbox Testers**.
2. Create a sandbox tester account (use a unique email not tied to a real Apple ID).
3. On your test device, sign out of the App Store and sign in with the sandbox account.
4. Sandbox subscriptions auto-renew on an accelerated schedule:
   - 1 month = 5 minutes
   - 1 year = 1 hour

### 7.2 Google Play Sandbox

1. Go to **Google Play Console > Settings > License Testing**.
2. Add your test Gmail accounts.
3. Set license response to `RESPOND_NORMALLY`.
4. Test subscriptions renew on an accelerated schedule:
   - 1 month = 5 minutes
   - 1 year = 30 minutes

### 7.3 RevenueCat Sandbox Mode

1. In RevenueCat Dashboard, navigate to a customer.
2. Toggle **Sandbox** mode to see sandbox transactions.
3. Use the RevenueCat debug overlay in the app during development:

```dart
// Add to debug builds only
await Purchases.setLogLevel(LogLevel.debug);
```

---

## 8. Verification Checklist

- [ ] Products created in App Store Connect and Google Play Console
- [ ] Products appear in RevenueCat Dashboard under the correct app
- [ ] Entitlement `premium` created and all 3 products attached
- [ ] Offering `default` created with monthly, annual, and lifetime packages
- [ ] Offering marked as **Current**
- [ ] Sandbox tester accounts created for both platforms
- [ ] App successfully loads offerings via `offeringsProvider`
- [ ] Purchase flow works in sandbox (monthly, yearly, lifetime)
- [ ] Restore purchases works correctly
- [ ] `EntitlementGate` correctly shows/hides premium content
- [ ] Free trial (7-day) is active and displays correctly
- [ ] `showAdsProvider` returns `false` for premium users
