# Refurb Watch — Instructions

Refurb Watch is a personal macOS app that checks Apple Canada’s certified refurbished store for products close to the configuration you describe.

## Start monitoring the included iPhone

1. Open **Refurb Watch.app**.
2. Select **Allow** when macOS asks for notification permission.
3. Find the included **Refurbished iPhone 16 Pro 256GB – Black Titanium** task.
4. To change the interval, press **Edit**, choose the desired interval, and save the task. The initial interval is five minutes.
5. Turn **Desktop notification** and **Sound** on or off as desired.
6. Press **Start Monitoring**. The first check runs immediately.

The app checks only while it is running. Closing or minimizing its window does not stop monitoring. To stop everything, choose **Refurb Watch → Quit Refurb Watch** or press **Command-Q**.

Each task’s running or paused status is saved. Tasks that were running automatically resume the next time you open the app. Paused tasks remain paused.

## Add another product

1. Press **Add Task**.
2. Describe one product in ordinary language. Include every detail that matters to you, such as model, storage, colour, chip, memory, screen size, connectivity, or display finish.
3. Press **Review Match**.
4. Review the inferred Apple Store category and the **Apple product title or important details** field.
5. Correct either field if necessary.
6. Select a checking interval from 30 seconds to 24 hours.
7. Choose the notification and sound settings, then press **Save Task**.
8. Press that task’s **Start Monitoring** button, or use **Start All** to start every saved task.

## How close matching works

Every meaningful detail you enter must appear in Apple’s listing, but Apple may add harmless or unspecified details.

For example, this description:

> Refurbished iPhone 16 Pro 256GB – Black Titanium

matches Apple’s listing:

> Refurbished iPhone 16 Pro 256GB – Black Titanium (Unlocked)

The added **(Unlocked)** label does not prevent a match. Capitalization, punctuation, spacing, word order, the word **Refurbished**, and fulfillment labels such as **Unlocked** or **SIM-Free** are also normalized.

Important configuration conflicts are not accepted. A different model, such as **Pro Max** instead of **Pro**, or a different storage size or colour will not match. When you specify connectivity or display finish, conflicting choices are rejected as well.

If you omit a detail, the app may accept any value for that detail. For example, leaving out storage could allow any storage size. Include all details you care about to keep alerts specific.

## Task controls and status

- **Start Monitoring / Pause** controls one task.
- **Start All** starts every task.
- **Check Now** checks immediately. For a running task, monitoring then continues on its normal interval; for a paused task, it performs a one-time check and remains paused.
- **Edit** changes the description, category, interval, or alert settings.
- **Delete** permanently removes a task.
- Each task shows its current status, matched product, price, last check, next check, and connection errors.
- A connection error is not treated as an out-of-stock result.

## Alerts and opening Apple’s website

The app alerts once when a matching product becomes available. It does not repeat alerts while that product remains available. If the product disappears and later returns, the app alerts again.

Clicking a notification brings Refurb Watch forward and displays **Cancel** and **Go to Website**. Apple’s website opens only after you press **Go to Website**.

## Data and privacy

- Product descriptions are parsed locally on your Mac.
- No AI account, API key, or cloud AI service is used.
- Tasks are saved in your macOS Application Support folder.
- Inventory checks contact Apple Canada’s refurbished-store pages.
- Email notifications are not included in this version.
