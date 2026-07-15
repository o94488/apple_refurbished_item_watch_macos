# Refurb Watch

Refurb Watch is a lightweight macOS app that monitors Apple Canada's Certified Refurbished Store and lets you know when a product matching your preferred configuration is available.

Describe the product you want, choose how often to check, and leave the app running. Refurb Watch can monitor several products at once, show the matching listing and price, and send a desktop notification or play a sound when it finds a match.

> [!NOTE]
> Refurb Watch is an independent personal utility. It is not affiliated with or endorsed by Apple.

## Requirements

- An Apple silicon Mac
- macOS 15.0 or later
- An internet connection

## Install and open the app

1. Download this repository and unzip it if necessary.
2. Open the `outputs` folder.
3. Drag **Refurb Watch.app** into your **Applications** folder. You can also run it directly from `outputs`.
4. Open **Refurb Watch**.
5. Select **Allow** when macOS asks for notification permission.

The included app is distributed independently with an ad-hoc signature. If macOS does not open it normally, Control-click **Refurb Watch.app**, choose **Open**, then confirm **Open**.

## Quick start

Refurb Watch includes an example task for a **Refurbished iPhone 16 Pro 256GB – Black Titanium**.

1. Find the example task on the main screen.
2. Use **Edit** if you want to change its product description, check interval, or alert settings.
3. Choose whether you want a **Desktop notification**, a **Sound**, or both.
4. Select **Start Monitoring**. The first inventory check runs immediately.

The app checks inventory only while it is running. Closing or minimizing the window does not stop it, but quitting the app does. To stop all monitoring, choose **Refurb Watch → Quit Refurb Watch** or press **Command-Q**.

## Add a product to watch

1. Select **Add Task**.
2. Describe one product in ordinary language. Include every detail that matters to you, such as model, chip, memory, storage, screen size, colour, connectivity, or display finish.
3. Select **Review Match**.
4. Check the inferred **Store category** and **Apple product title or important details**. Correct either field if needed.
5. Choose a check interval from 30 seconds to 24 hours.
6. Choose your notification and sound settings.
7. Select **Save Task**.
8. Select **Start Monitoring** on the new task, or use **Start All** to start every saved task.

Supported store categories are Mac, iPad, iPhone, AirPods, Apple TV, HomePod, and Accessories.

For example, you could enter:

> Refurbished MacBook Air 13-inch with M3 chip, 16GB memory, 512GB SSD, Midnight

Product descriptions are interpreted locally on your Mac. No AI account or API key is required. Always review the generated match before saving it.

## How product matching works

Every meaningful detail in the reviewed product title must appear in Apple's listing. Apple may include extra details that you did not specify.

For example, this target:

> Refurbished iPhone 16 Pro 256GB – Black Titanium

can match this Apple listing:

> Refurbished iPhone 16 Pro 256GB – Black Titanium (Unlocked)

Capitalization, punctuation, spacing, word order, the word “Refurbished,” and fulfillment labels such as “Unlocked” or “SIM-Free” do not affect matching.

Important configuration conflicts are rejected. For example, **Pro** will not match **Pro Max**, and a different storage size or colour will not be accepted. Explicit connectivity and display-finish choices must also agree.

If you leave out a detail, the app may accept any value for it. Leaving out storage, for example, may match any storage capacity. Include all the details you care about to keep alerts specific.

## Task controls

- **Start Monitoring / Pause** starts or pauses one task.
- **Start All** starts every saved task.
- **Check Now** performs an immediate check. A paused task remains paused afterward; a running task continues on its normal interval.
- **Edit** changes the description, category, interval, and alert settings.
- **Delete** permanently removes the task after confirmation.

Each task displays its current status, target or matched product, price when available, last check, next scheduled check, and any connection error.

| Status | Meaning |
| --- | --- |
| Paused | Automatic checks are stopped. |
| Waiting | Monitoring has started and is waiting to run a check. |
| Checking | The app is contacting Apple's store. |
| In Stock | A close-enough matching listing was found. |
| Out of Stock | No matching listing was found in the current inventory. |
| Connection Error | The check could not be completed. This is not treated as out of stock. |

Running and paused states are saved. Tasks that were running resume automatically the next time you open the app; paused tasks remain paused.

## Notifications and sounds

Refurb Watch alerts once when a matching product becomes available. It will not repeat the alert while that product remains available. If the match disappears and later returns, the app alerts you again.

- Turn on **Desktop notification** to receive a macOS notification.
- Turn on **Sound** to add a sound to the notification. If desktop notifications are off, the app can play a standalone sound instead.
- Select a notification to bring Refurb Watch forward. The app asks for confirmation before opening Apple's product page in your browser.

If notifications are not appearing, open **System Settings → Notifications → Refurb Watch** and make sure notifications are allowed.

## Troubleshooting

### The app stops checking

Refurb Watch must remain open. Closing its window is fine, but quitting the app stops all checks until you launch it again.

### A product does not match

Edit the task and compare **Apple product title or important details** with the wording on Apple's refurbished store. Remove a detail you do not care about, fix a conflicting option, or confirm that the correct store category is selected.

### A task shows Connection Error

Check your internet connection and select **Check Now**. Apple's store pages may also be temporarily unavailable or may have changed. The app keeps connection failures separate from out-of-stock results.

## Data and privacy

- Product descriptions are parsed locally on your Mac.
- No AI service, account, or API key is used.
- Inventory checks contact Apple Canada's refurbished-store pages.
- Tasks are stored locally at `~/Library/Application Support/RefurbWatch/watch-tasks.json`.
- Email alerts and background checks while the app is quit are not supported.

## Build from source

The repository is a Swift Package. To build the included Apple silicon app bundle with the provided script, install Apple's Command Line Tools and run:

```sh
./scripts/package_app.sh
```

The app is created at `outputs/Refurb Watch.app`. Run the local test suite with:

```sh
./scripts/run_tests.sh
```
