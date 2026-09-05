# Shipping 1.1.0 to the Mac App Store

Everything below is done on your Mac with your Apple ID. The repo already carries version 1.1.0, build 10.

## 1. Archive in Xcode (5 minutes)

1. Open `SleepTimer.xcodeproj` in Xcode and sign in under Xcode > Settings > Accounts if you aren't already.
2. Select the `SleepTimer` scheme and **Any Mac** as the destination.
3. Choose **Product > Archive**. Xcode signs with your Apple Development certificate and opens the Organizer when done.
4. If Xcode reports a signing problem, open the project's Signing & Capabilities tab, confirm the team is Smartfast Labs, and let it repair provisioning.

## 2. Test the archived build once (5 minutes)

Do this before uploading. It's the first build that is signed and sandboxed, and sleeping the Mac is the one thing a sandbox can block.

1. In the Organizer, select the archive and click **Distribute App**, then **Custom**, then **Copy App**. Save it somewhere.
2. Launch that copy. Open Settings from the popover and set the idle wait to 30 seconds.
3. Start a 15-minute timer, then leave the Mac alone for a minute. It should sleep with no countdown.
4. Wake it. Quit that copy and delete it, so it doesn't conflict with the App Store version later.

If it does not sleep, stop here and tell me. Nothing else needs to change until that works.

## 3. Upload (5 minutes)

1. In the Organizer, select the archive and click **Distribute App**.
2. Choose **App Store Connect**, then **Upload**. Accept the defaults for symbols and version management.
3. Wait for "Upload Successful". Processing on Apple's side takes 5 to 20 minutes; you'll get an email.

## 4. Fill in the listing (10 minutes)

On https://appstoreconnect.apple.com, open Smart Sleep Timer.

1. Click **+** next to the macOS app version and enter **1.1.0**.
2. Paste each field from `docs/appstore/listing.md`: promotional text, description, keywords, What's New, and the three URLs.
3. Drag the five PNGs from `docs/appstore/screenshots/` into the Mac screenshots area, in numeric order.
4. Under **Build**, click **+** and pick build 10 once processing has finished.
5. Confirm **App Privacy** still shows "Data Not Collected". If it asks again, answer as in the listing file.
6. Confirm copyright reads 2026 Smartfast Labs LLC and the category is Utilities.

## 5. Submit

1. Click **Add for Review**, then **Submit to App Review**.
2. Review typically takes one to two days for an update like this.

## If review asks for anything

The most likely question is why the app runs `pmset`. The answer: it is the system's own sleep command, run inside the sandbox with no elevated privileges, and it's the same mechanism the currently approved 1.0.9 uses. Send me the exact message and I'll draft the reply.
