# Privacy Policy Hosting Instructions

## Overview

Your privacy policy has been created at `docs/PRIVACY_POLICY.md`. Now you need to host it online so you can link to it from:
- Apple App Store Connect
- Google Play Console  
- Within your app (Profile screen)

---

## Option 1: GitHub Pages (Recommended - Free & Easy)

### Step 1: Enable GitHub Pages

```bash
# 1. Go to your GitHub repository
open https://github.com/yangakandeni/carlet/settings/pages

# 2. Under "Source", select "Deploy from a branch"
# 3. Select branch: main (or create a gh-pages branch)
# 4. Select folder: /docs
# 5. Click "Save"

# Wait 1-2 minutes for deployment
```

### Step 2: Access Your Privacy Policy

Your privacy policy will be available at:
```
https://yangakandeni.github.io/carlet/PRIVACY_POLICY
```

### Step 3: Create HTML Version (Optional - Better Formatting)

GitHub Pages automatically renders Markdown, but for better control:

```bash
# Create an HTML version
cd /Users/techolosh/development/projects/carlet/docs

# You can use pandoc to convert MD to HTML
brew install pandoc
pandoc PRIVACY_POLICY.md -o privacy-policy.html -s --metadata title="Carlet Privacy Policy"

# Or create a simple HTML wrapper (see below)
```

### Step 4: Custom Domain (Optional)

If you own a domain:
```bash
# 1. Create CNAME file in docs/
echo "yourdomain.com" > docs/CNAME

# 2. Add DNS records at your domain registrar
# Type: CNAME
# Name: www (or @)
# Value: yangakandeni.github.io

# 3. Update GitHub Pages settings with custom domain
```

---

## Option 2: Firebase Hosting (Also Free)

### Step 1: Initialize Firebase Hosting

```bash
cd /Users/techolosh/development/projects/carlet

# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize hosting (if not already)
firebase init hosting

# Select:
# - Use existing project: carlet-dev-6be6a (or your production project)
# - Public directory: docs
# - Single-page app: No
# - Set up automatic builds: No
```

### Step 2: Create index.html

```bash
# Create a simple index in docs/
cat > docs/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Carlet - Privacy & Legal</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
        a { color: #007AFF; text-decoration: none; }
    </style>
</head>
<body>
    <h1>Carlet - Legal Documents</h1>
    <ul>
        <li><a href="privacy-policy.html">Privacy Policy</a></li>
        <li><a href="terms-of-service.html">Terms of Service</a> (coming soon)</li>
    </ul>
</body>
</html>
EOF
```

### Step 3: Convert Markdown to HTML

```bash
# Using pandoc
pandoc PRIVACY_POLICY.md -o privacy-policy.html -s \
  --metadata title="Carlet Privacy Policy" \
  --css=style.css

# Or use an online converter
# Copy PRIVACY_POLICY.md content and paste at:
# https://markdowntohtml.com/
```

### Step 4: Deploy

```bash
firebase deploy --only hosting

# Your privacy policy will be at:
# https://carlet-dev-6be6a.web.app/privacy-policy.html
# Or your custom domain if configured
```

---

## Option 3: Netlify (Free Tier)

### Step 1: Sign Up

```bash
# 1. Go to https://www.netlify.com/
# 2. Sign up with GitHub
# 3. Click "Add new site" → "Import an existing project"
# 4. Connect your GitHub repository
# 5. Set build settings:
#    - Base directory: docs
#    - Publish directory: docs
# 6. Click "Deploy site"
```

### Step 2: Configure

```bash
# Create netlify.toml in your repo root
cat > netlify.toml << 'EOF'
[build]
  publish = "docs"

[[redirects]]
  from = "/privacy"
  to = "/PRIVACY_POLICY.html"
  status = 200

[[redirects]]
  from = "/privacy-policy"
  to = "/PRIVACY_POLICY.html"
  status = 200
EOF

# Commit and push - Netlify will auto-deploy
```

Your privacy policy will be at:
```
https://your-site-name.netlify.app/PRIVACY_POLICY
```

You can also add a custom domain in Netlify settings.

---

## Option 4: Your Own Website

If you have a personal website or company website:

1. Copy the content of `PRIVACY_POLICY.md`
2. Convert to HTML or use your CMS
3. Upload to: `https://yourdomain.com/carlet/privacy-policy`
4. Ensure it's accessible via HTTPS

---

## After Hosting

### 1. Update App Store Connect (iOS)

```bash
# 1. Go to App Store Connect
open https://appstoreconnect.apple.com/

# 2. Select your app
# 3. Go to "App Information"
# 4. Add Privacy Policy URL: https://your-hosted-url/privacy-policy
# 5. Save
```

### 2. Update Google Play Console (Android)

```bash
# 1. Go to Play Console
open https://play.google.com/console/

# 2. Select your app
# 3. Go to "Store presence" → "Store settings"
# 4. Add Privacy Policy URL: https://your-hosted-url/privacy-policy
# 5. Save
```

### 3. Add Link in App (Profile Screen)

See the code changes below for adding a privacy policy link to your Profile screen.

### 4. Test the Link

```bash
# Make sure the URL is accessible
curl -I https://your-hosted-url/privacy-policy

# Should return: HTTP/1.1 200 OK
```

---

## Required Contact Information

**IMPORTANT:** Update the privacy policy with your actual contact information:

In `docs/PRIVACY_POLICY.md`, replace:
- `[your-email@example.com]` → Your real support email
- `[Your Company Name]` → Your company/individual name
- `[Street Address]` → Your physical address (required for Play Store)
- `[dpo@example.com]` → Data Protection Officer email (if applicable)

```bash
# Quick find and replace
cd /Users/techolosh/development/projects/carlet/docs
# Edit PRIVACY_POLICY.md and replace all [placeholders]
```

---

## Recommended: Simple HTML Template

Create `docs/privacy-policy.html` with better formatting:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Carlet Privacy Policy</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        h1 { color: #007AFF; border-bottom: 2px solid #007AFF; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        h3 { color: #666; }
        a { color: #007AFF; }
        .last-updated { color: #666; font-style: italic; }
        .summary-box { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
        code { background: #f0f0f0; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <!-- Copy the rendered content from PRIVACY_POLICY.md here -->
    <!-- Or use a Markdown-to-HTML converter -->
</body>
</html>
```

---

## Next Steps

1. ✅ Choose a hosting option (GitHub Pages recommended)
2. ✅ Host the privacy policy
3. ✅ Update contact information in the policy
4. ✅ Add URL to app store listings
5. ✅ Add link in the app (see code below)
6. ✅ Test that the URL works

---

## Questions?

- For GitHub Pages issues: https://docs.github.com/en/pages
- For Firebase Hosting: https://firebase.google.com/docs/hosting
- For Netlify: https://docs.netlify.com/
