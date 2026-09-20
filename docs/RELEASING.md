# Releasing Family Altar

This guide covers publishing the app to the App Store and Google Play from GitHub.

- **[Part 1: One-time setup](#part-1-one-time-setup)**: do this once, in order.
- **[Part 2: Releasing a new version](#part-2-releasing-a-new-version)**: do this for every release.
- [Maintenance](#maintenance) and [Troubleshooting](#troubleshooting) are at the end.

## How it works

Releases run as three workflows in the **Actions** tab of the app repo on GitHub:

1. **Release: Prepare** opens a pull request that bumps `version:` in `pubspec.yaml` and adds the release notes as `release-notes/<version>.txt`. You choose how much to bump the version and type the notes when you start it. `pubspec.yaml` is the source of truth for the version.
2. **Release: Build & Upload** runs after that pull request is merged. It builds the iOS and Android apps from `main` with the version in `pubspec.yaml` and uploads them to TestFlight and Google Play's closed testing track, where the team can try them. It then tags the commit with the version and build number, for example `v1.2.0+23`.
3. **Release: Deploy** takes one of those tags and ships that exact build. The iOS build is submitted for App Store review and goes live automatically when Apple approves it. The Android build is released to 100% of Google Play users.

Three other pieces make this work:

- **Secrets.** The workflows need passwords and keys, such as the signing certificates and the store login keys. GitHub stores these as *secrets*: workflows can read them, but nobody can view them after they're saved.
- **Environments.** A GitHub *environment* is a named set of secrets plus rules about when they can be used. This repo uses two:
  - `store-upload` is used by Build & Upload. It only runs from `main`.
  - `production` is used by Deploy. It only runs from `main`, and it waits until Cipher73 or jeremyscodes approves.
- **The content repo.** The app repo is public, so the book text isn't in it (`*.txt` is gitignored). The workflows copy the text in from a private repo, `Family-Altar/family-altar-content`.

GitHub never stores the builds. Anyone can download files from a public repo, and the apps contain the book text, so TestFlight and Google Play hold the builds instead.

## Part 1: One-time setup

### Before you start

You need:

- **Admin access to the app repo** (`Family-Altar/family-altar-mobile`) on GitHub, so you can open its Settings. You also need permission to create repos in the `Family-Altar` organization.
- **The Mac that has made releases before.** Only that Mac has:
  - the book `.txt` files in `assets/`
  - the Android upload key: `android/app/upload-keystore.jks` and `android/key.properties`
  - the Apple Distribution certificate in its keychain
- **The Google Play Console owner or an Admin** for step 5.
- **The Apple Developer account holder or an Admin** for step 7.
- **The workflow files on `main`.** GitHub only lists workflows in the Actions tab once they're on the default branch.

Terminal commands in this guide run in one of three places, and each command block starts with a comment saying which:

| Place | What it is |
|---|---|
| **App repo** | The root folder (the one with `pubspec.yaml`) of your clone of `Family-Altar/family-altar-mobile`. |
| **Content repo** | Your clone of `Family-Altar/family-altar-content`. Step 2 creates it next to the app repo. |
| **Scratch folder** | A temporary folder outside both repos. Keys and certificates go here so they can never be committed. |

### Step 1: Create the two GitHub environments

Create the environments first. Each later step then gives you a secret to save in them straight away.

**Create `store-upload`:**

1. On GitHub, open the app repo and click **Settings** in the top bar.
2. In the left sidebar, click **Environments**, then **New environment**.
3. Name it `store-upload` and click **Configure environment**.
4. Under **Deployment branches and tags**, change **No restriction** to **Selected branches and tags**. Click **Add deployment branch or tag rule**, type `main`, and click **Add rule**.

Leave everything else as it is. Builds don't need approval, so anyone with write access can start one.

**Create `production`:**

1. Go back to **Environments** and click **New environment**.
2. Name it `production` and click **Configure environment**.
3. Tick **Required reviewers** and add `Cipher73` and `jeremyscodes`. Either one can approve a deploy. Leave **Prevent self-review** unticked, so whoever starts a deploy can also approve it.
4. Click **Save protection rules**.
5. Under **Deployment branches and tags**, restrict it to `main` the same way you did for `store-upload`.

**Let workflows open pull requests** (Release: Prepare needs this):

1. In the app repo, go to **Settings → Actions → General**.
2. Under **Workflow permissions**, tick **Allow GitHub Actions to create and approve pull requests** and click **Save**.

If the checkbox is greyed out, the `Family-Altar` organization blocks it. An organization owner has to turn on the same setting under the organization's **Settings → Actions → General** first.

**How to add an environment secret.** Each of the next steps ends with a table of environment secrets to add. For each row:

1. Go to **Settings → Environments** and click the environment named in the table.
2. Under **Environment secrets**, click **Add environment secret**.
3. Type the **Name** exactly as shown, paste the **Value**, and click **Add secret**.

Every value in this guide is an **environment secret**. You won't add any environment variables:

- **Leave the Environment variables section empty.** It's on the same page, but the workflows don't read it, and anyone who can see the settings can read a variable.
- **Don't use repository or organization secrets.** They would also work, but then any workflow on any branch could read them, and the `main`-only and approval rules wouldn't protect them.

Most commands in this guide end in `pbcopy`, which puts the value on your clipboard. Paste it straight into the **Value** box.

### Step 2: Create the private content repo

1. On GitHub, create a new repository with owner `Family-Altar`, name `family-altar-content`, and visibility **Private**. Don't add a README, .gitignore or license.
2. On the Mac with the book files, clone it next to the app repo and copy the book text into it:

   ```bash
   # In the app repo
   git clone https://github.com/Family-Altar/family-altar-content.git ../family-altar-content
   for v in volume_I volume_II volume_III; do
     rsync -a --include='*/' --include='*.txt' --exclude='*' "assets/$v/" "../family-altar-content/$v/"
   done
   ```

3. Commit and push:

   ```bash
   # In the content repo
   cd ../family-altar-content
   printf '* -text\n' > .gitattributes   # Volume III is UTF-16; never convert line endings
   find . -name '*.txt' -not -path './.git/*' | wc -l   # should print 1100
   git add -A
   git commit -m "Add book content"
   git branch -M main
   git push -u origin main
   ```

   The 1,100 files are every day of the three volumes, plus Volume I's `Foreword.txt` and `Preface.txt`, Volume II's `Preface.txt`, and Volume III's `preface.txt`.

### Step 3: Let the workflows read the content repo

The workflows read the content repo with a *deploy key*, an SSH key that can read that one repo and nothing else.

1. Create the key in a scratch folder. Never create it inside a repo; the app repo is public.

   ```bash
   # In a scratch folder
   cd "$(mktemp -d)"
   ssh-keygen -t ed25519 -N "" -C "family-altar-mobile releases" -f content_deploy_key
   pbcopy < content_deploy_key.pub
   ```

2. The public half of the key is now on your clipboard. On GitHub, open the **content repo** → **Settings** → **Deploy keys** → **Add deploy key**. Title it `family-altar-mobile releases` and paste the key. Leave **Allow write access** unticked, then click **Add key**. This goes on the content repo as a **deploy key**, not as a secret.
3. Copy the private half:

   ```bash
   # In the same scratch folder
   pbcopy < content_deploy_key
   ```

4. Add it to the **app repo** (not the content repo) as an **environment secret**:

   | Environment | Secret name | Value |
   |---|---|---|
   | `store-upload` | `CONTENT_REPO_DEPLOY_KEY` | The private key you just copied |

5. Delete the key files:

   ```bash
   # In the same scratch folder
   rm content_deploy_key content_deploy_key.pub
   ```

### Step 4: Add the Android upload key

Google Play only accepts app bundles signed with the app's upload key. The key is gitignored, so it's only on the Mac that has made Android releases.

1. Copy the keystore:

   ```bash
   # In the app repo, on the Mac that has made Android releases
   base64 -i android/app/upload-keystore.jks | pbcopy
   ```

   Save it as the `ANDROID_KEYSTORE_B64` environment secret (see the table below).

2. Show the passwords and alias:

   ```bash
   # In the app repo
   cat android/key.properties
   ```

   Ignore the `storeFile` line. The workflow sets its own.

3. Add these **environment secrets**:

   | Environment | Secret name | Value |
   |---|---|---|
   | `store-upload` | `ANDROID_KEYSTORE_B64` | Output of the `base64` command |
   | `store-upload` | `ANDROID_KEYSTORE_PASSWORD` | `storePassword` from `key.properties` |
   | `store-upload` | `ANDROID_KEY_ALIAS` | `keyAlias` from `key.properties` |
   | `store-upload` | `ANDROID_KEY_PASSWORD` | `keyPassword` from `key.properties` |

### Step 5: Give the workflows access to Google Play

*Needs the Google Play Console owner or an Admin.*

The workflows sign in to Google Play as a *service account*, a Google account meant for software rather than a person.

1. Create the service account in the [Google Cloud console](https://console.cloud.google.com):
   1. At the top of the page, choose the app's existing project (**Family Altar App**). Only create a new project if there isn't one or you can't manage it. The project just holds the service account; the Play Console invite in the next part is what connects it to the app.
   2. Open the [Google Play Android Developer API page](https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com), check that the right project is selected at the top, and click **Enable**. If the button says **Manage**, the API is already on.
   3. Open the [Service accounts page](https://console.cloud.google.com/iam-admin/serviceaccounts) and click **Create service account**. Name it `github-releases` and click **Create and continue**. Skip the two optional screens that offer to grant access (click **Continue**, then **Done**). The service account needs no Google Cloud permissions; its access is set in Play Console below.
   4. Click the new account and copy its email address, which ends in `iam.gserviceaccount.com`. You need it in a moment.
   5. Open the **Keys** tab → **Add key** → **Create new key** → **JSON** → **Create**. A `.json` file downloads.
2. Give it access in [Play Console](https://play.google.com/console). This is a different website from Google Cloud (`play.google.com/console`). Don't use Google Cloud's **IAM** or **Grant access** pages for this.
   1. On the Play Console home page, where your apps are listed, click **Users and permissions** in the left sidebar, then **Invite new users**.
   2. Paste the service account's email address.
   3. On the **App permissions** tab, click **Add app**, choose **Family Altar**, and tick these permissions:
      - View app information and download bulk reports (read-only)
      - Release to production, exclude devices, and use Play App Signing
      - Release apps to testing tracks
      - Manage testing tracks and edit tester lists
   4. Click **Apply**, then **Invite user**. New permissions can take a few hours to start working.
3. Copy the key file:

   ```bash
   # Anywhere; use the name of the file that downloaded
   pbcopy < ~/Downloads/your-key-file.json
   ```

4. Add it as an **environment secret** in **both** environments. Environments can't share secrets, so you add it twice:

   | Environment | Secret name | Value |
   |---|---|---|
   | `store-upload` | `PLAY_SERVICE_ACCOUNT_JSON` | The whole JSON file |
   | `production` | `PLAY_SERVICE_ACCOUNT_JSON` | The same JSON file |

5. Delete the downloaded `.json` file.

### Step 6: Add the Apple signing certificate and profile

Apple only accepts apps signed with the team's distribution certificate and provisioning profile. The certificate is in the keychain of the Mac that has archived iOS releases.

1. Export the certificate:
   1. Open **Keychain Access** (search for it with Spotlight). Choose the **login** keychain and **My Certificates**.
   2. Find **Apple Distribution: Timothy Dodd (BH49HZGJ7F)** and its private key. Usually the key is under the certificate's arrow. If they're listed as two separate rows instead, click the certificate, then **Cmd-click** the private key so both are selected.
   3. Right-click and choose **Export…** (or **Export 2 items…**). Set **File Format** to **Personal Information Exchange (.p12)** and save it to the Desktop as `distribution.p12`.
   4. Keychain asks you to set a password. Choose a strong one; you'll save it as a secret too. If Keychain doesn't ask, or the file ends in `.cer`, it exported only the certificate without the private key, and CI can't sign with that. Go back and make sure the private key is included.
2. Copy the certificate:

   ```bash
   # Anywhere
   base64 -i ~/Desktop/distribution.p12 | pbcopy
   ```

   Save it as the `IOS_DIST_CERT_P12_B64` environment secret (see the table below). Then copy the provisioning profile:

   ```bash
   # In the app repo
   base64 -i Family_Altar_iOS_Provision_Profile.mobileprovision | pbcopy
   ```

3. Add these **environment secrets**:

   | Environment | Secret name | Value |
   |---|---|---|
   | `store-upload` | `IOS_DIST_CERT_P12_B64` | Output of the first `base64` command |
   | `store-upload` | `IOS_DIST_CERT_PASSWORD` | The password you set on the `.p12` |
   | `store-upload` | `IOS_PROVISIONING_PROFILE_B64` | Output of the second `base64` command |

4. Delete `~/Desktop/distribution.p12`. You can also remove the profile from the app repo in a normal PR.

### Step 7: Give the workflows access to App Store Connect

*Needs the Apple Developer account holder or an Admin.*

The workflows use an App Store Connect API key to upload builds and submit them for review.

1. In [App Store Connect](https://appstoreconnect.apple.com), go to **Users and Access → Integrations → App Store Connect API → Team Keys**. If you see **Request Access**, the account holder has to click it first.
2. Click **Generate API Key** (or **+**). Name it `GitHub releases`, set **Access** to **App Manager**, and click **Generate**.
3. Note two values on that page: the **Issuer ID** above the table, and the **Key ID** in the new key's row.
4. Click **Download** next to the key. Apple only lets you download it once. The file is named `AuthKey_<Key ID>.p8`.
5. Copy it:

   ```bash
   # Anywhere; put your Key ID in the file name
   pbcopy < ~/Downloads/AuthKey_XXXXXXXXXX.p8
   ```

6. Add these as **environment secrets** in **both** environments, so each name goes in twice:

   | Environment | Secret name | Value |
   |---|---|---|
   | `store-upload` and `production` | `ASC_KEY_ID` | Key ID |
   | `store-upload` and `production` | `ASC_ISSUER_ID` | Issuer ID |
   | `store-upload` and `production` | `ASC_KEY_P8` | The whole `.p8` file, including the `BEGIN` and `END` lines |

7. Delete the `.p8` file. If you need it again later, revoke the key and generate a new one.

### Step 8: Set up testers

Every build goes to TestFlight and Google Play closed testing before it ships. To install a build on a phone before release, you need to be a tester there. The workflows don't need testers, so skipping this doesn't break anything; you just can't try builds before they ship.

- **Google Play:** in Play Console, open Family Altar → **Testing → Closed testing**, then the **Alpha** track → **Testers**. Add an email list with your Google accounts, **tick the checkbox next to it**, and click **Save**. The list only gets builds while it's ticked; you only need to do this once. Then open the join link on your phone and accept.
- **TestFlight (optional):** in App Store Connect, open Family Altar → **TestFlight** → **Internal Testing**. Create a group, add yourselves, and turn on automatic distribution. Then install the TestFlight app on your iPhone. Without this, iOS builds still upload and ship, but nobody can try them on an iPhone first.

Both consoles move their menus around from time to time. If you can't find these pages, look for "closed testing".

### Step 9: Check everything

- [ ] `store-upload` is limited to `main` and has 12 environment secrets:
  - `CONTENT_REPO_DEPLOY_KEY`
  - `ANDROID_KEYSTORE_B64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
  - `PLAY_SERVICE_ACCOUNT_JSON`
  - `IOS_DIST_CERT_P12_B64`, `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_B64`
  - `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`
- [ ] `production` is limited to `main`, lists Cipher73 and jeremyscodes as required reviewers, and has 4 environment secrets: `PLAY_SERVICE_ACCOUNT_JSON`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`.
- [ ] Neither environment has any environment variables.
- [ ] **Allow GitHub Actions to create and approve pull requests** is ticked under **Settings → Actions → General**.
- [ ] The content repo has 1,100 `.txt` files, and its deploy key doesn't have write access.
- [ ] Both stores list the app's main language as **English (U.S.)**. Release notes are sent in that language. If either store uses a different one, change `STORE_LOCALE` in `fastlane/Fastfile`.

That finishes setup. Your first real build is the real test: if a secret is wrong, the job that uses it fails with an error naming the problem.

## Part 2: Releasing a new version

Make sure the changes you want to release are merged into `main` first.

### 1. Prepare the release

1. On GitHub, open the app repo's **Actions** tab and click **Release: Prepare** in the left sidebar.
2. Click **Run workflow** and fill in:
   - **Use workflow from:** `main`
   - **Version bump:** how much to raise the version in `pubspec.yaml`:
     - `patch` for fixes: `1.1.1` → `1.1.2`
     - `minor` for new features: `1.1.1` → `1.2.0`
     - `major` for big changes: `1.1.1` → `2.0.0`
   - **What's new:** the release notes, in plain text, 500 characters at most. They appear in TestFlight, in Google Play's "What's new", and in the App Store's "What's New in This Version". The box only takes one line, but you can add line breaks in the pull request. For example:

     ```text
     You can now highlight passages in the daily reading, add notes to them, and find them all again in the new Highlights list.
     ```

3. Click the green **Run workflow** button. It takes under a minute.

The run opens a pull request called **Release 1.2.0** (with your version) on a `release/1.2.0` branch. It changes two files:

- `pubspec.yaml`: `version:` becomes the new version. There's no `+number` build number; the build workflow picks that.
- `release-notes/1.2.0.txt`: your release notes.

Check the notes in the pull request, edit them on that branch if you need to, and **merge it**. Because a workflow opened the pull request, GitHub doesn't run the Analyze check on it. That's expected: it only changes the version and the notes.

### 2. Build and upload

1. In the **Actions** tab, click **Release: Build & Upload**.
2. Click **Run workflow**. Leave **Use workflow from** set to `main` and **Build number override** empty, then click the green **Run workflow** button.
3. Wait 30–60 minutes. Most of that time is Apple processing the upload. No approval is needed.

The build uses the version in `pubspec.yaml` and the notes in `release-notes/<version>.txt`. When the run turns green:

- The build is in TestFlight and in Google Play closed testing. Google reviews closed testing releases, so it can be a few hours before testers can install it.
- A new pre-release appears under **Releases** in the right sidebar of the app repo's main page. It's named something like `1.2.0 (23)` and tagged `v1.2.0+23`. You'll need that tag to ship.

If the run fails, open the failed job to read the error, then see [Troubleshooting](#troubleshooting).

### 3. Test the build

Install the build on an Android phone from the closed testing link. If you've set up TestFlight, install it on an iPhone too.

If something's wrong, merge a fix into `main` and run **Build & Upload** again. Don't run Prepare again: the version stays the same, and the new build gets a higher build number and a new tag.

### 4. Ship it

1. Open the **Actions** tab and click **Release: Deploy**.
2. Click **Run workflow** and fill in:
   - **Use workflow from:** `main`
   - **Build tag to release:** the tag from step 2, e.g. `v1.2.0+23`
   - **Stores to release to:** `both`, unless you only want one store
3. Click **Run workflow**.
4. The run stops and waits for approval. Cipher73 or jeremyscodes opens the run, clicks **Review deployments**, ticks `production`, and clicks **Approve and deploy**. GitHub also notifies both reviewers.

After approval:

- **iOS:** the build is submitted for review and goes live automatically when Apple approves it, usually within a day or two.
- **Android:** the build is released to 100% of Google Play users. Google reviews updates first, which can take a few hours or a few days.
- **GitHub:** the release is marked **Latest**.

### Good to know

- **Android can only ship the newest build.** Each upload replaces the one waiting in closed testing. If you've built again since, deploy the newer tag.
- **If Apple rejects the build,** merge a fix, run Build & Upload again (not Prepare), and deploy the new tag with **Stores to release to** set to `ios`.
- **If a build fails partway,** open the run and click **Re-run failed jobs**. It reuses the build number it already picked, so no number is skipped or used twice.
- **Build numbers** are one above the highest build in either store, and iOS and Android get the same number. Only use the override if a store rejects the number that was picked.
- **`version:` in `pubspec.yaml` is the source of truth.** Change it only through Release: Prepare, which keeps it in step with the release notes file. The version must be higher than the one live on the App Store, or the build stops with an error.

## Maintenance

- **The Apple certificate and profile expire on 2027-06-09.** Renew both before then and update the three `IOS_*` secrets in `store-upload` (Part 1, step 6). If the new profile has a different name, also update `ios/ExportOptions.plist` and the Release-production signing settings in Xcode.
- **Xcode version.** The iOS build uses Xcode `26.6`, set by `XCODE_VERSION` in `.github/workflows/release-build.yml`. When you upgrade Xcode locally, change it there too.
- **Changing the book text.** Push the change to the content repo. The next build uses it, and each GitHub release notes which content commit it was built from.
- **Running a lane locally.** In the app repo, install Ruby 3.4 (see `.ruby-version`) and run `bundle install`. Then export the secrets the lane needs in your terminal (for example `export ASC_KEY_ID=...`) and run `bundle exec fastlane <lane>`. `bundle exec fastlane lanes` lists the lanes.

## Troubleshooting

| Error | What to do |
|---|---|
| `Version X in pubspec.yaml isn't above Y, which is live on the App Store` | Start a new release with **Release: Prepare**, merge its pull request, then build. |
| `release-notes/X.txt is missing` | The version in `pubspec.yaml` was changed without Release: Prepare. Add the notes file in a pull request, or start over with Prepare. |
| `The release notes are N characters; Google Play allows 500` | Shorten `release-notes/<version>.txt` in a pull request, then build again. |
| Prepare: `The branch release/X already exists` | A pull request for that version is already open. Merge it, or close it and delete the branch. |
| Prepare: `GitHub Actions is not permitted to create or approve pull requests` | Turn on the setting in Part 1, step 1 ("Let workflows open pull requests"). |
| `assets/volume_…/daily_readings has N reading files` | Files are missing from the content repo. |
| The "Check out book content" step fails with a permission error | Check the deploy key (Part 1, step 3). |
| `Xcode 26.6 isn't on this runner image` | Set `XCODE_VERSION` to one of the versions listed in the error. |
| `Build N isn't on the alpha track` | A newer build replaced it. Deploy the newest tag. |
| Google Cloud won't let you create a JSON key | Your organization's policy blocks service account keys. Use a project outside the organization, or ask its admin to allow keys for this project. |

If a release has to go out while the pipeline is broken, follow the manual iOS steps in `ios/RELEASE_CHECKLIST.md`.
