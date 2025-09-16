# GitHub Actions Release Setup

This document explains how to set up automated releases using GitHub Actions.

## Overview

Once configured, you can create releases by simply tagging and pushing:
```bash
git tag v1.0.1
git push origin v1.0.1
```

The GitHub Action will automatically:
1. Build the app with Swift
2. Code sign with your Developer ID certificate
3. Create and sign a DMG
4. Notarize with Apple
5. Create a GitHub release with the notarized DMG

## Required GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

### 1. DEVELOPER_CERTIFICATE_P12
**Export your Developer ID certificate as .p12:**

1. Open **Keychain Access**
2. Find your certificate: "Developer ID Application: Alexander Hart (M9QW4CBDY8)"
3. **Right-click** → Export
4. **Format**: Personal Information Exchange (.p12)
5. **Save** with a password (remember it!)
6. **Encode to base64**:
   ```bash
   base64 -i /path/to/your/certificate.p12 | pbcopy
   ```
7. **Paste** the base64 output into GitHub secret

### 2. CERTIFICATE_PASSWORD
The password you used when exporting the .p12 file above.

### 3. APPLE_ID
Your Apple ID email address (same one used for Developer Program).

### 4. APPLE_APP_PASSWORD
Your app-specific password for notarization (you already created this).

### 5. APPLE_TEAM_ID
Your Apple Developer Team ID: **M9QW4CBDY8**

## Testing the Workflow

### First Test (Dry Run)
1. **Commit all changes**:
   ```bash
   git add .
   git commit -m "Add GitHub Actions workflow"
   git push
   ```

2. **Create and push a test tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **Watch the workflow** at: GitHub → Actions tab

### If the Workflow Fails

Common issues:
- **Certificate import fails**: Check DEVELOPER_CERTIFICATE_P12 and CERTIFICATE_PASSWORD
- **Notarization fails**: Verify APPLE_ID, APPLE_APP_PASSWORD, and APPLE_TEAM_ID
- **Build fails**: Check that build-app.sh works locally first

### Debugging Tips

1. **Check Actions logs** for detailed error messages
2. **Test locally first**: Run `./build-app.sh` and `./create-dmg.sh` locally
3. **Verify secrets**: Double-check all secret values are correct

## Release Process

Once set up, creating releases is simple:

```bash
# Make your changes
git add .
git commit -m "Fix bug in solar power display"

# Create release
git tag v1.0.1
git push origin v1.0.1
```

The GitHub Action will:
- ✅ Build a signed app
- ✅ Create a signed DMG
- ✅ Notarize with Apple
- ✅ Create GitHub release
- ✅ Upload notarized DMG as download

## File Structure

The workflow uses these files:
- `.github/workflows/release.yml` - GitHub Actions workflow
- `build-app.sh` - Builds and signs the app bundle
- `create-dmg.sh` - Creates and signs the DMG
- `Sources/HomeAssistantMenuBar/Info.plist` - App metadata

All manual scripts have been removed as they're no longer needed.