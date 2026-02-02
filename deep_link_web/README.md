# Wish Listy - Deep Link Web Assets

This folder contains web assets for native deep linking support for the Wish Listy Flutter app.

## Files Structure

```
deep_link_web/
├── index.html                          # Landing page for deep links
├── .well-known/
│   ├── assetlinks.json                # Android App Links verification
│   └── apple-app-site-association     # iOS Universal Links verification (no extension)
├── vercel.json                         # Vercel configuration
└── README.md                           # This file
```

## Setup Instructions

1. **Get SHA-256 Fingerprint** (for Android):
   - See `GET_SHA256.md` for instructions
   - Update `assetlinks.json` with your SHA-256 value

2. **Get Team ID** (for iOS):
   - Get your Apple Developer Team ID
   - Update `apple-app-site-association` with your Team ID

3. **Deploy to Vercel**:
   - See `DEPLOY_VERCEL.md` for deployment instructions

## Configuration

### Android (assetlinks.json)
- Package name: `com.amr.wishlisty`
- SHA-256: Already configured (debug keystore)
- For production, update with release keystore SHA-256

### iOS (apple-app-site-association)
- Bundle ID: `com.example.wishListy`
- Team ID: Replace `REPLACE_WITH_TEAM_ID`
- Paths: `/wishlist/*`, `/event/*`, `*`

## Custom Domain

After deployment, you can add a custom domain in Vercel settings:
- Recommended: `links.wishlisty.app` or similar
- This domain should be used in your app's deep link configuration

## Testing

1. Verify assetlinks.json:
   - Visit: `https://YOUR-DOMAIN.vercel.app/.well-known/assetlinks.json`
   - Should return valid JSON

2. Verify apple-app-site-association:
   - Visit: `https://YOUR-DOMAIN.vercel.app/.well-known/apple-app-site-association`
   - Should return valid JSON with `Content-Type: application/json`

## Support

For issues or questions:
- Check `GET_SHA256.md` for Android setup
- Check `DEPLOY_VERCEL.md` for deployment
- Check `INSTALL_JAVA.md` if you encounter Java issues

