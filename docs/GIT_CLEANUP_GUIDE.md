# Git History Cleanup Guide

## Overview

Your repository currently has sensitive files committed to git history that should be removed before making the repository public or before final deployment.

## 🔴 Sensitive Files in History

The following files contain sensitive information and are in your git history:

1. **`android/app/google-services.json`** - Contains Firebase configuration and API keys
2. **`ios/Runner/GoogleService-Info.plist`** - Contains Firebase configuration and API keys
3. **`ios/Runner/Info.plist`** - Contains exposed Google Maps API key: `AIzaSyA9gO0qGZdMVZcTxFB3hKbcWSo8QGy0WJE`

These files are correctly in `.gitignore` now, but they were committed in the past and remain in git history.

---

## ⚠️ Important Warnings

**Before cleaning git history:**
1. ✅ Ensure all team members have pushed their changes
2. ✅ Notify team members about the history rewrite
3. ✅ Backup your repository: `git clone --mirror <repo-url> backup.git`
4. ✅ This will change commit hashes and require force-push
5. ✅ All team members will need to re-clone or reset their local repos

**After cleaning:**
1. 🔄 Rotate ALL API keys and secrets that were exposed
2. 🔄 Generate new Firebase configuration files
3. 🔄 Create new Google Maps API keys with restrictions

---

## Method 1: BFG Repo-Cleaner (Recommended - Fast & Easy)

### Step 1: Install BFG

```bash
# macOS
brew install bfg

# Or download from https://rtyley.github.io/bfg-repo-cleaner/
```

### Step 2: Clone a Fresh Mirror

```bash
cd ~/Desktop
git clone --mirror https://github.com/yangakandeni/carlet.git carlet-cleanup.git
cd carlet-cleanup.git
```

### Step 3: Remove Sensitive Files

```bash
# Remove specific files from all history
bfg --delete-files google-services.json
bfg --delete-files GoogleService-Info.plist

# If you want to also replace the exposed API key in Info.plist:
echo "AIzaSyA9gO0qGZdMVZcTxFB3hKbcWSo8QGy0WJE" > secrets.txt
bfg --replace-text secrets.txt

# Clean up the repository
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### Step 4: Verify Changes

```bash
# Check that files are removed
git log --all --full-history -- "**/google-services.json"
git log --all --full-history -- "**/GoogleService-Info.plist"

# Should return no results
```

### Step 5: Force Push

```bash
# Push the cleaned history (⚠️ THIS REWRITES HISTORY)
git push --force
```

### Step 6: Team Re-sync

Notify all team members to re-clone:

```bash
cd ~/development/projects
rm -rf carlet
git clone https://github.com/yangakandeni/carlet.git
cd carlet
flutter pub get
```

---

## Method 2: git-filter-repo (Alternative - More Control)

### Step 1: Install git-filter-repo

```bash
# macOS
brew install git-filter-repo

# Or: pip3 install git-filter-repo
```

### Step 2: Create a Fresh Clone

```bash
cd ~/Desktop
git clone https://github.com/yangakandeni/carlet.git carlet-cleanup
cd carlet-cleanup
```

### Step 3: Remove Files

```bash
# Remove specific files from all history
git filter-repo --path android/app/google-services.json --invert-paths
git filter-repo --path ios/Runner/GoogleService-Info.plist --invert-paths

# Or remove multiple files in one command
git filter-repo --invert-paths \
  --path android/app/google-services.json \
  --path ios/Runner/GoogleService-Info.plist
```

### Step 4: Force Push

```bash
# Add the remote back (filter-repo removes it)
git remote add origin https://github.com/yangakandeni/carlet.git

# Force push
git push origin --force --all
git push origin --force --tags
```

---

## Method 3: Native Git (Most Control, More Complex)

### Using git filter-branch (Legacy Method)

```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch android/app/google-services.json ios/Runner/GoogleService-Info.plist" \
  --prune-empty --tag-name-filter cat -- --all

git reflog expire --expire=now --all
git gc --prune=now --aggressive

git push origin --force --all
git push origin --force --tags
```

---

## Post-Cleanup Actions

### 1. Rotate All Exposed Secrets

**Google Maps API Key:**
```bash
# 1. Go to Google Cloud Console
# 2. Navigate to APIs & Services > Credentials
# 3. Delete key: AIzaSyA9gO0qGZdMVZcTxFB3hKbcWSo8QGy0WJE
# 4. Create new key with iOS/Android app restrictions
# 5. Update ios/Runner/Info.plist with new key
```

**Firebase Configuration:**
```bash
# 1. Go to Firebase Console
# 2. Download fresh google-services.json (Android)
# 3. Download fresh GoogleService-Info.plist (iOS)
# 4. Place in correct directories (they're gitignored)
# 5. Consider creating new Firebase project for production
```

### 2. Update .gitignore (Already Done)

Verify these entries exist in `.gitignore`:
```
**/google-services.json
**/GoogleService-Info.plist
android/key.properties
```

### 3. Create Template Files

Create `android/app/google-services.json.template`:
```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "YOUR_PROJECT_ID"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "YOUR_APP_ID",
        "android_client_info": {
          "package_name": "com.techolosh.carletdev"
        }
      },
      "api_key": [
        {
          "current_key": "YOUR_FIREBASE_API_KEY"
        }
      ]
    }
  ]
}
```

### 4. Update README.md

Add instructions for team members:
```markdown
## Firebase Setup

1. Download Firebase configuration files from Firebase Console
2. Place `google-services.json` in `android/app/`
3. Place `GoogleService-Info.plist` in `ios/Runner/`
4. These files are gitignored - do not commit them
```

---

## Verification Checklist

After cleanup, verify:

- [ ] `git log --all -- "**/google-services.json"` returns no results
- [ ] `git log --all -- "**/GoogleService-Info.plist"` returns no results
- [ ] GitHub repository shows no sensitive files in history
- [ ] All API keys have been rotated
- [ ] New Firebase config files are in place locally
- [ ] App builds and runs with new configuration
- [ ] Team members have re-cloned repository
- [ ] CI/CD pipelines updated with new secrets

---

## Alternative: Just Rotate Keys

If you don't want to rewrite history (simpler but less secure):

1. **Accept that old keys are in history**
2. **Rotate/revoke all exposed keys immediately**
3. **Use new keys going forward**
4. **Keep repository private**

This is acceptable if:
- Your repository is and will remain private
- You rotate all keys immediately
- You monitor for unauthorized usage
- You plan to create a fresh repo for public release

---

## For Production Deployment

Consider creating a completely new repository:

```bash
# Create new repo with clean history
cd ~/Desktop
mkdir carlet-production
cd carlet-production
git init

# Copy current code (not git history)
cp -r ~/development/projects/carlet/* .
rm -rf .git
git init
git add .
git commit -m "Initial commit - production release"

# Create new GitHub repo and push
git remote add origin https://github.com/yangakandeni/carlet-production.git
git push -u origin main
```

---

## Support Resources

- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [git-filter-repo Documentation](https://github.com/newren/git-filter-repo)
- [GitHub: Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Firebase Security Best Practices](https://firebase.google.com/docs/projects/api-keys)

---

## Questions?

If you're unsure about any step, **DO NOT PROCEED**. Ask for help from someone experienced with git history rewriting. Incorrectly rewriting history can cause data loss.
