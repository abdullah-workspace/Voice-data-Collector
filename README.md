# HearAssist Data Collector

**HearAssist Data Collector** is a specialized, production-grade Android application built with Flutter to record and curate acoustic environmental sound samples for the **HearAssist** final-year project.

The dataset collected by this tool is used to train machine learning models that alert deaf and hard-of-hearing individuals about critical acoustic events in their surroundings.

---

## 1. Project Overview & Scope

This application has **one primary responsibility**:
* **Record high-fidelity environmental audio samples, categorize them accurately, store them locally with rich contextual metadata, and export the complete dataset as a structured ZIP archive.**

The tool purposefully omits machine learning inference, cloud synchronisation, user authentication, or intrusive background services in order to guarantee **100% recording reliability, strict acoustic format adherence, zero data loss, and rapid data collection workflows.**

---

## 2. Audio Format Specifications

All recordings strictly adhere to standard acoustic ML training requirements:

| Parameter | Specification | Notes |
| :--- | :--- | :--- |
| **Container Format** | WAV | Canonical 44-byte RIFF header |
| **Encoding** | PCM Signed 16-bit | Little-endian integer samples (`audio/x-raw`) |
| **Sample Rate** | 16,000 Hz (16 kHz) | Standard for environmental sound classification |
| **Channel Count** | 1 (Mono) | Single audio channel |
| **Configurable Durations** | **2 seconds, 3 seconds** | Configured in Settings (**Default: 3 seconds**) |

> **Format Safeguard**: The application enforces strictly 2-second or 3-second clips. Any legacy setting (e.g., 5 seconds) is automatically and safely migrated to 3 seconds. Furthermore, if the native hardware encoder ever fails to output a RIFF header, the app synthesizes a canonical 44-byte WAV header over raw PCM bytes before finalization.

---

## 3. Fixed Sound Categories

The dataset defines six immutable classes configured in `lib/config/categories.dart`:

| # | Category ID | Display Name | Role / Description |
|---|---|---|---|
| 1 | `clapping` | **Clapping** | Hand clapping at varying speeds, distances, and intensities |
| 2 | `doorbell` | **Doorbell** | Chimes, buzzers, and electronic/mechanical doorbells |
| 3 | `door_knock` | **Door Knock** | Knocks on wood, metal, glass, and hollow doors |
| 4 | `baby_cry` | **Baby Cry** | Infant crying, whimpering, and distress vocalizations |
| 5 | `microwave_oven` | **Microwave Oven** | Completion beeps, appliance hums, and latch sounds |
| 6 | `background_noise` | **Background Noise** | **Negative class**: conversations, appliances, traffic, silence |

---

## 4. File Naming Convention

Every audio sample is saved with a deterministic, collision-proof filename:

```
<category>_<collector>_<device>_<NNNN>.wav
```

### Components
* `<category>`: The internal folder name (e.g. `door_knock`, `doorbell`).
* `<collector>`: Sanitized name of the data collector (alphanumeric only, lowercased).
* `<device>`: Sanitized hardware label (e.g. `samsunga14`, `pixel7`).
* `<NNNN>`: A 4-digit sequential counter padded with leading zeros (e.g. `0001`, `0042`).

### Examples
```
clapping_abdullah_samsunga14_0001.wav
clapping_abdullah_samsunga14_0002.wav
doorbell_abdullah_samsunga14_0001.wav
door_knock_abdullah_samsunga14_0007.wav
```

> **Counter Persistence**: The counter evaluates existing `.wav` files in the category directory on disk and increments from the maximum found number. Counters remain persistent across app restarts and reboots.

---

## 5. Storage & Metadata Architecture

### Directory Structure
Recordings are stored in the app-specific external files directory (`Android/data/com.hearassist.hearassist_data_collector/files/HearAssistDataset/`):

```
HearAssistDataset/
├── clapping/
│   ├── clapping_abdullah_samsunga14_0001.wav
│   └── ...
├── doorbell/
├── door_knock/
├── baby_cry/
├── microwave_oven/
├── background_noise/
└── metadata.csv
```

### `metadata.csv` Schema
Every successfully saved recording appends exactly one row to `metadata.csv`. Columns are strictly ordered:

| Column # | Field Name | Valid Values / Example |
|---|---|---|
| 1 | `filename` | `doorbell_abdullah_samsunga14_0001.wav` |
| 2 | `category` | `doorbell` |
| 3 | `collector` | `abdullah` |
| 4 | `device` | `samsunga14` |
| 5 | `duration_sec` | `2.0` or `3.0` |
| 6 | `sample_rate` | Always `16000` |
| 7 | `timestamp_iso`| UTC ISO 8601 (e.g. `2026-11-25T16:00:00.000Z`) |
| 8 | `environment` | `bedroom`, `living room`, `kitchen`, `outdoor`, `street`, `hallway`, `other` |
| 9 | `distance` | `near (<1m)`, `medium (1–3m)`, `far (>3m)` |
| 10 | `noise_level` | `quiet`, `moderate`, `noisy` |
| 11 | `notes` | Free-form contextual notes (escaped in CSV) |

When an audio file is deleted via the Library screen, its associated row is safely removed from `metadata.csv` to keep files and metadata synchronized.

---

## 6. Premium Design System

The application uses a centralized Material 3 design system:
* **Palette**:
  * Primary Navy: `#102A43`
  * Secondary Teal: `#2A9D8F`
  * Background: `#F7F8F6`
  * Surface: `#FFFFFF`
  * Text Primary: `#102A43`
  * Text Secondary: `#52606D`
  * Borders: `#D9E2EC`
  * Success: `#2A9D8F`
  * Error: `#C94C4C`
* **Typography**: Reusable styles centralized in `lib/app/theme/app_typography.dart`.
* **Themes**: Full support for Light and Dark themes via `lib/app/theme/app_theme.dart`.

---

## 7. User Guide: Data Collection Workflow

### Step 1: Configuration (Settings Tab)
1. Open the **Settings** tab.
2. Enter your **Collector Name** (e.g. `abdullah`).
3. Enter your **Device Model / Label** (e.g. `samsungA14`).
4. Select the target **Recording Duration**: **2 Seconds** or **3 Seconds** (Default: 3 Seconds).
5. Set your collection target per category (default: `200`).
6. Tap the prominent **Save Changes** button. *(Unsaved changes prompt a confirmation dialog if you attempt to leave without saving).*

### Step 2: Recording (Dashboard Tab)
1. Tap any category card on the dashboard.
2. Grant microphone permission if prompted.
3. Tap the central **Record** button:
   * Screen stays awake automatically via wake lock.
   * Visual countdown counts down (e.g. `3, 2, 1...`).
   * Live audio input level meter provides real-time amplitude feedback.
4. When finished, the app automatically transitions to the **Review Screen**.

### Step 3: Review & Metadata
1. Play back the clip to verify acoustic quality.
2. Choose the contextual metadata (Environment, Distance, Noise Level, Notes).
3. Tap **Save Sample** to append to `metadata.csv` and move the file into the category folder.
4. Or tap **Discard** (with confirmation prompt) to permanently delete the temporary recording.

### Step 4: Library Management
* Open the **Library** tab to browse clips by category.
* Play back previously saved samples.
* Delete accidental or poor-quality recordings with confirmation (safely updates `metadata.csv`).

---

## 8. Exporting the Dataset

1. In **Settings** > **Export Dataset** (or via the Export screen), tap **Create ZIP & Share**.
2. The app packages all 6 category folders and `metadata.csv` into:
   ```
   HearAssistDataset_YYYY-MM-DD.zip
   ```
3. The native Android share sheet opens automatically to share via Quick Share, Google Drive, Email, or cloud storage.
4. Alternatively, transfer via USB MTP cable or ADB:
   ```bash
   adb pull /storage/emulated/0/Android/data/com.hearassist.hearassist_data_collector/files/HearAssistDataset/ ./HearAssistDataset/
   ```

---

## 9. Installing the Release APK on Android

1. Locate the built APK file:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```
2. Copy the APK to your Android device via USB cable, Quick Share, Google Drive, or ADB:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
3. If installing directly on phone:
   * Open the APK using the Files app.
   * Allow "Install from unknown sources" if prompted.
   * Tap **Install** and open **HearAssist Data Collector**.
