<img src="./.github/assets/app-icon.png" alt="Voice assistant app icon" width="100" height="100">

# Flutter Agent Starter

This starter app template for [LiveKit Agents](https://docs.livekit.io/agents/overview/) provides a simple voice interface using the [LiveKit Flutter SDK](https://github.com/livekit/client-sdk-flutter). It supports [voice](https://docs.livekit.io/agents/start/voice-ai/), [transcriptions](https://docs.livekit.io/agents/build/text/), [live video input](https://docs.livekit.io/agents/build/vision/#video), and [virtual avatars](https://docs.livekit.io/agents/integrations/avatar/).

This template is compatible with iOS, macOS, Android, and web. It is free for you to use or modify as you see fit.

<img src="./.github/assets/screenshot.png" alt="Voice Assistant Screenshot" height="500">

## Getting started

First, you'll need a LiveKit agent to speak with. Try our starter agent for [Python](https://github.com/livekit-examples/agent-starter-python), [Node.js](https://github.com/livekit-examples/agent-starter-node), or [create your own from scratch](https://docs.livekit.io/agents/start/voice-ai/).

Second, you need a token server. The easiest way to set this up is with the [Sandbox for LiveKit Cloud](https://cloud.livekit.io/projects/p_/sandbox) and the [LiveKit CLI](https://docs.livekit.io/home/cli/cli-setup/).

First, create a new [Sandbox Token Server](https://cloud.livekit.io/projects/p_/sandbox/templates/token-server) for your LiveKit Cloud project.

Then, run the following command to automatically clone this template and connect it to LiveKit Cloud.

```bash
lk app create --template agent-starter-flutter --sandbox <token_server_sandbox_id>
```

This will create a new Flutter project in the current directory. Install dependencies and run the app:
```bash
flutter pub get
flutter run
```

Note: You may need to configure signing certificates in Xcode if building to a real iOS device.

> [!NOTE]
> To setup without the LiveKit CLI, clone the repository and then either create a `.env` with a `LIVEKIT_SANDBOX_ID` (if using a [Sandbox Token Server](https://cloud.livekit.io/projects/p_/sandbox/templates/token-server)), or modify `lib/controllers/app_ctrl.dart` to replace the `SandboxTokenSource` with your own token source implementation (development-only hardcoded credentials are also supported there).

## Feature overview

This starter app supports several features of the agents framework and is intended as a base you can adapt for your own use case.

### Text, video, and voice input

This app supports:

- **Voice**: send microphone audio to your agent. **Requires microphone permissions.**
- **Text**: send text input using the message bar.
- **Video**: optionally share camera and/or screen share tracks to the room so your agent can process visual input (requires an agent/model that supports it).

Related docs:

- Voice agents: https://docs.livekit.io/agents/start/voice-ai/
- Text: https://docs.livekit.io/agents/build/text/
- Vision/video: https://docs.livekit.io/agents/build/vision/#video
- Screen share: https://docs.livekit.io/home/client/tracks/screenshare/

If you have trouble with screen sharing, refer to the docs linked above for more setup instructions.

### Session

The app is built around two core concepts:

- `livekit_client.Session`: connects to LiveKit, dispatches/observes the agent, and provides a message history via `session.messages` as well as helpers like `session.sendText(...)`.
- `livekit_components.RoomContext` / `MediaDeviceContext`: manages local media tracks (microphone, camera, screen share) and their lifecycle.

### Preconnect audio buffer

This app enables `preConnectAudio` by default to capture and buffer audio before the room connection completes. This allows the connection to appear "instant" from the user's perspective and makes the app more responsive.

To disable this feature, set `preConnectAudio` to `false` in `SessionOptions` when creating the `Session` (see `lib/controllers/app_ctrl.dart`).

### Virtual avatar / agent video

If your agent publishes a video track (for example via a [virtual avatar](https://docs.livekit.io/agents/integrations/avatar/) integration), the app renders the agent's video when available and falls back to an audio visualizer otherwise.

## Token generation in production

In a production environment, you will be responsible for developing a solution to [generate tokens for your users](https://docs.livekit.io/home/server/generating-tokens/) that integrates with your authentication system.

You should replace the `SandboxTokenSource` in `lib/controllers/app_ctrl.dart` with an `EndpointTokenSource` or your own `TokenSourceFixed` / `TokenSourceConfigurable` implementation. You can also use `.cached()` to cache valid tokens and avoid unnecessary token requests.

## Running on Simulator / Emulator

To use this template with video (or screen sharing) input, you may need to run the app on a physical device depending on platform and simulator/emulator capabilities. Testing on Simulator/Emulator will still support voice and text modes.

## Contributing

This template is open source and we welcome contributions! Please open a PR or issue through GitHub, and don't forget to join us in the [LiveKit Community Slack](https://livekit.io/join-slack)!

## 自定義 WebRTC 實作 (Custom WebRTC Implementation)

本專案使用的是 **自定義修補過的 WebRTC AAR**，而非標準官方版本。

### 為什麼？
我們需要實作 **右聲道靜音 (Right Channel Mute)** 功能。然而測試發現，Android 下的 WebRTC 經常協商出 **單聲道 (Mono, 1-channel)** 音訊，系統會自動將其播放到雙邊喇叭。這導致單純在軟體層面靜音右聲道的邏輯失效（因為輸入源本身就是單聲道）。

### 解決方案：強制立體聲轉換 (Forced Stereo Upmixing)
我們修改了 `webrtc-android` 函式庫中的 `WebRtcAudioTrack.java` 類別，做了以下調整：
1.  **偵測單聲道輸入**：檢查協商出的 Session 是否為單聲道。
2.  **強制立體聲輸出**：無視輸入格式，強制將 Android `AudioTrack` 初始化為立體聲模式。
3.  **升頻與靜音 (Upmix & Mute)**：手動將單聲道訊號轉換為立體聲（左聲道 = 原始訊號，右聲道 = 靜音/0）。

### 檔案位置
修改後的 AAR 位於本專案的本地目錄中：
- **路徑**：`android/repo/io/github/webrtc-sdk/android/137.7151.04-modified/`
- **檔案**：`android-137.7151.04-modified.aar`

專案已在 `android/build.gradle` 中配置，優先使用此本地倉庫，並將所有標準 WebRTC 依賴替換為此特定版本。

### 版本對應說明 (Version Mapping)
本專案的依賴版本如下：
- **livekit_client**: `2.6.1`
- **flutter_webrtc**: `1.2.1`
- **Android WebRTC SDK**: `137.7151.04` (M137)

正因為 `flutter_webrtc 1.2.1` 預設依賴此特定版本的 WebRTC SDK，我們才針對 `137.7151.04` 進行下載與修補。
**注意**：若未來升級 `livekit_client` 或 `flutter_webrtc`，必須確認新的底層 WebRTC SDK 版本，並針對該新版本重新下載 AAR 進行上述的修補步驟。


### 本地 Maven 倉庫維護 (AAR & POM)

本專案使用本地 Maven 倉庫（位於 `android/repo`）來載入修補過的 AAR。

**⚠️ 重要檢查點 (POM 檔案)：**
當您更新 AAR 或手動建立目錄時，請務必確認 `.pom` 檔案內容。
- **路徑**：`android/repo/io/github/webrtc-sdk/android/137.7151.04-modified/android-137.7151.04-modified.pom`
- **內容核心**：裡面的 `<version>` 標籤內容必須與**資料夾名稱**及**檔案名稱**完全一致。
  ```xml
  <version>137.7151.04-modified</version>
  ```
- **失敗症狀**：如果 POM 內容與版本路徑不符，Gradle 會發生 `Could not find...` 錯誤，即使檔案確實在目錄下也一樣。

### 未來維護 / 更新
如果您需要更新 LiveKit（可能需要更新版本的 WebRTC）或再次修改此邏輯，請參考開發機上的 **WebRTC Solution Package**（位於 `~/Desktop/webrtc_solution_package`，或已另外封存）。

該套件包含：
- **`REPRODUCTION_GUIDE.md`**：AAR 集成指南。
- **`AAR_COMPILATION_GUIDE.md`**：從源碼重新編譯 AAR 的指南。
- **`webrtc_patch_demo/`**：可直接運行的 Gradle 專案，用於編譯 Java 修改代碼。
