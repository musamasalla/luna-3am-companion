# Luna App Store Connect Guide

## Step-by-Step Submission Checklist

### 1. App Store Connect Setup

#### Create App Record
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → "+" → New App
3. Fill in:
   - Platform: iOS
   - Name: Luna - 3AM Companion
   - Primary Language: English (U.S.)
   - Bundle ID: com.musamasalla.Luna-3AM-Companion
   - SKU: luna3amcompanion

---

### 2. App Information

#### General Information
| Field | Value |
|-------|-------|
| Name | Luna - 3AM Companion |
| Subtitle | Your Gentle Night Companion |
| Category | Health & Fitness |
| Secondary Category | Lifestyle |
| Content Rights | Yes, I own all rights |

#### Privacy Policy URL
```
https://musamasalla.github.io/luna-3am-companion/privacy.html
```

---

### 3. Pricing and Availability

#### App Price
- Price: **Free**
- Availability: **Worldwide** (all territories)

#### In-App Purchases
| Product | Type | Price |
|---------|------|-------|
| Luna Premium | Auto-Renewable Subscription | $2.99/month |

#### Subscription Setup
1. Features → In-App Purchases → Manage
2. Create Subscription Group: "Premium"
3. Add Product:
   - Reference Name: Monthly Premium
   - Product ID: com.musamasalla.luna.premium.monthly
   - Subscription Duration: 1 Month
   - Subscription Price: $2.99
   - Free Trial: 7 days

---

### 4. Version Information

#### What's New
```
🌙 Welcome to Luna!

Your gentle AI companion for late-night conversations is finally here.

• Unlimited conversations with Luna
• Beautiful dark theme for 3AM browsing
• Conversation history
• Premium subscription with 7-day free trial

Can't sleep? Luna understands. 💜
```

#### Description
See APP_STORE_OPTIMIZATION.md for full description.

#### Keywords
```
sleep,insomnia,anxiety,late night,companion,AI chat,mental health,calm,relax,3am,nighttime,thoughts
```

#### Support URL
```
https://musamasalla.github.io/luna-3am-companion/
```

#### Marketing URL (optional)
```
https://musamasalla.github.io/luna-3am-companion/
```

---

### 5. Build Upload

#### From Xcode
1. Select target device: "Any iOS Device (arm64)"
2. Product → Archive
3. Distribute App → App Store Connect → Upload

#### Verify in App Store Connect
- Go to TestFlight → Builds
- Wait for processing (5-15 minutes)
- Check for any issues flagged

---

### 6. App Review Information

#### Contact Information
| Field | Value |
|-------|-------|
| First Name | Musa |
| Last Name | Masalla |
| Phone | (your phone) |
| Email | musamasalladev@gmail.com |

#### Demo Account
*(Not required - app doesn't require login)*

#### Notes for Reviewer
```
Luna is an AI companion app for late-night conversations. No account is required.

To test subscription:
1. Complete onboarding
2. Tap "Go Premium" from chat or settings
3. Use sandbox account to test purchase flow

The app uses Firebase Gemini AI for responses. Internet connection required for AI features.
```

---

### 7. Age Rating

| Question | Answer |
|----------|--------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content and Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, Drugs | None |
| Simulated Gambling | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | Infrequent/Mild ✓ |
| Mature/Suggestive Themes | None |
| Unrestricted Web Access | No |
| Gambling and Contests | No |

**Result: 4+ rating**

---

### 8. App Privacy

#### Privacy Practices
1. Collect Data: **No** (conversations stored locally only)
2. Data Linked to User: **No**
3. Data Used to Track: **No**

#### Purchase History
Since app has subscriptions, acknowledge:
- Purchase History: Used to verify subscription status
- Linked to User: No (anonymous via StoreKit)
- Used to Track: No

---

### 9. Screenshots

#### Required Devices
Upload screenshots for at least one of each screen size class:
- 6.9" (iPhone 17 Pro Max) - Required
- 6.5" (iPhone 16 Pro Max)
- 6.1" (iPhone 17 Pro)
- 5.5" (iPhone 8 Plus)

#### Screenshot Content
1. **Onboarding/Welcome**
2. **Chat Interface** (in conversation)
3. **Luna Avatar** (close-up of animation)
4. **Dark Theme** (showing night-friendly design)
5. **Settings/Premium** (subscription features)

#### Screenshot Specs
- Format: PNG or JPEG
- No alpha/transparency
- High resolution (use simulator screenshots)

---

### 10. Pre-Submission Checklist

- [ ] App builds and runs without crashes
- [ ] All screenshots uploaded
- [ ] Description and keywords finalized
- [ ] Age rating questionnaire completed
- [ ] Privacy policy URL accessible
- [ ] Support URL accessible
- [ ] Subscription products configured
- [ ] Build uploaded and processed
- [ ] Review notes prepared

---

### 11. Submit for Review

1. Review all sections for completeness
2. Click "Add for Review"
3. Answer export compliance questions:
   - Uses encryption: **Yes** (HTTPS)
   - Exempt from documentation: **Yes** (standard HTTPS only)
4. Submit

#### Expected Review Time
- First submission: 24-48 hours
- Updates: 12-24 hours

---

## Post-Submission

### If Rejected
1. Read rejection notes carefully
2. Fix cited issues
3. Reply with explanation of changes
4. Resubmit

### If Approved
1. Set release manually or auto-release
2. Monitor initial reviews
3. Prepare marketing materials

---

*Last updated: February 2026*
