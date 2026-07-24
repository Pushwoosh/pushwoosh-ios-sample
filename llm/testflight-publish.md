# Publishing the Pushwoosh sample to TestFlight

How to build the sample app and upload it to TestFlight. A helper script does the whole
flow; the manual steps it automates are documented at the bottom for reference.

## What the flow does

The sample's dev bundle id is `com.pushwoosh.PushwooshSampleApp*`. TestFlight needs the
production id `com.pushwoosh.PushwooshSampleAppProd*`. The script:

1. Temporarily swaps `PRODUCT_BUNDLE_IDENTIFIER = com.pushwoosh.PushwooshSampleApp*` →
   `…Prod*` in `project.pbxproj` (app + its extensions; test targets untouched).
2. Archives (Release, `generic/platform=iOS`) and exports an `.ipa` (automatic signing,
   `-allowProvisioningUpdates`).
3. Uploads to TestFlight with `xcrun altool` using an App Store Connect API key.
4. **Restores `project.pbxproj` byte-for-byte** on exit — success, failure, or Ctrl-C —
   via an EXIT trap, so the repo bundle id is never left changed.

Marketing version and build number are passed as `xcodebuild` overrides (no pbxproj edit),
so every upload is unique and App Store Connect won't reject it as a duplicate.

## One-time setup

1. **Xcode** with command-line tools (`xcodebuild`, `xcrun altool`).
2. **App Store Connect API key** (needs access to the Pushwoosh ASC team, `EZ696X67SZ`):
   ASC → *Users and Access → Integrations → App Store Connect API* → generate a key with
   the *App Manager* role (or higher).
3. Download the `.p8` **once** and place it at
   `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`
   (or point `ASC_KEY_PATH` at it).
4. Copy the creds template and fill it in:
   ```bash
   cp llm/.testflight.env.example llm/.testflight.env
   # edit llm/.testflight.env → set ASC_KEY_ID and ASC_ISSUER_ID
   ```
   `llm/.testflight.env` is gitignored. You can also just `export ASC_KEY_ID=… ASC_ISSUER_ID=…`
   instead of the file.

## Run it

```bash
# dry run first — swap → archive → export → revert, NO upload (verifies signing/build)
llm/testflight-sample.sh --dry-run

# real upload (auto-bumps the patch of the last used marketing version)
llm/testflight-sample.sh

# force a specific marketing version
llm/testflight-sample.sh --version 7.2.0
```

- The build number is always a fresh timestamp.
- Without `--version`, the marketing version is the patch-bump of the last one used
  (persisted in `llm/.testflight.version`, gitignored; first run seeds from the project).
- After upload the build takes a few minutes to appear in TestFlight (processing).

## Overridable env

| Var | Default | Purpose |
|-----|---------|---------|
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | — | ASC API key creds (required for upload) |
| `ASC_KEY_PATH` | `~/.appstoreconnect/private_keys/AuthKey_<ID>.p8` | explicit `.p8` path |
| `PW_TEAM_ID` | `EZ696X67SZ` | signing team |
| `PW_EXPORT_METHOD` | `app-store-connect` | use `app-store` on older Xcode |
| `PW_SAMPLE_DIR` | repo path (auto) | override the sample project dir |

## Troubleshooting

- **`ASC_KEY_ID not set`** → creds missing; fill `llm/.testflight.env` or export the vars.
- **`ASC key not found`** → `.p8` not at the expected path; set `ASC_KEY_PATH`.
- **export method error on older Xcode** → `PW_EXPORT_METHOD=app-store llm/testflight-sample.sh`.
- **`bundle-id swap changed nothing`** → the sample's bundle prefix changed; update
  `BUNDLE_PREFIX` in the script.
- The script never leaves the repo dirty: if something fails mid-run, `project.pbxproj` is
  still restored (check `git status` — it should be clean afterwards).

## Manual equivalent (if you'd rather not use the script)

1. In `project.pbxproj`, change every `PRODUCT_BUNDLE_IDENTIFIER = com.pushwoosh.PushwooshSampleApp…`
   to `…PushwooshSampleAppProd…` (app + extensions, not test targets).
2. Archive:
   ```bash
   xcodebuild -workspace PushwooshSampleApp.xcworkspace -scheme PushwooshSampleApp \
     -configuration Release -destination "generic/platform=iOS" \
     -archivePath /tmp/PushwooshSampleApp.xcarchive -allowProvisioningUpdates \
     MARKETING_VERSION=7.2.0 CURRENT_PROJECT_VERSION=$(date +%Y%m%d%H%M%S) archive
   ```
3. Export with an `ExportOptions.plist` (`method=app-store-connect`, `teamID=EZ696X67SZ`,
   `signingStyle=automatic`) via `xcodebuild -exportArchive`.
4. Upload: `xcrun altool --upload-app --type ios --file <ipa> --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>`.
5. **Revert `project.pbxproj`** (`git checkout -- …/project.pbxproj`).
