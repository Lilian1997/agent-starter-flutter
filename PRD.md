# 專案需求總整理

## 一、硬體與環境

• **平台**：Android 車機 (Head Unit)。
• **解析度**：$1024 \times 600$ (橫向寬螢幕)。
• **開發框架**：Flutter。

## 二、核心功能

1. **身份驗證 (Authentication)**
    ◦ 使用 **Keycloak** 進行 OAuth2/OIDC 登入。
    ◦ 使用 `flutter_appauth` 處理登入流程。
    ◦ 使用 `flutter_secure_storage` 安全存儲 Keycloak Access Token。
2. **通話連線 (VoIP)**
    ◦ 使用者輸入「房間名稱」 (若無則預設進入「客服房間」)。
    ◦ App 攜帶 Keycloak Access Token 呼叫 **自建後端 API**。
    ◦ 後端驗證權限後，回傳 **LiveKit Token**。
    ◦ App 使用 LiveKit Token 連線至房間。
3. **通話介面 (UI)**
    ◦ **左側 (40%) 控制區**：顯示音波圖 (`AudioVisualizer`)、聲道控制按鈕 (左/中/右)、掛斷按鈕。
    ◦ **右側 (60%) 資訊區**：顯示即時逐字稿 (Transcript)。
4. **聲道控制 (Audio Control)**
    ◦ 透過 Android Native MethodChannel 控制底層 `AudioManager` 或 `AudioTrack` 的左右平衡 (Balance)。
5. **逐字稿 (STT)**
    ◦ 接收 LiveKit **Data Channel** 傳來的 JSON 資料。
    ◦ 即時更新 UI 列表。

## 三、技術架構

• **狀態管理**：Riverpod (`StateNotifier` / `AsyncNotifier`)。
• **UI 組件**：`livekit_components` (用於音波圖、連線狀態) + 自定義 Widget。

### 四、圖解說明與重點提示

1. **雙層 Token 機制 (Double Token Flow)**：
    - 圖中展示了兩個 Token：**Keycloak Token** (用於證明身份) 和 **LiveKit Token** (用於進入房間)。這是最安全的做法，LiveKit Token 是由你的後端簽發的短期通行證。
2. **STT 的角色 (Agent)**：
    - 我在圖中加入了一個 `STT Agent` 角色。這代表你後端的機器人（可能是 Python 寫的 LiveKit Agent），它負責「聽」LiveKit 的聲音，「轉」成文字，再透過 Data Channel「丟」回給 App。App 本身不做語音辨識，只負責顯示。
3. **Riverpod 的位置**：
    - 在 `Flutter App` 的直條中，所有的邏輯判斷（存 Token、打 API、更新 UI List）都是由 Riverpod 的 Controller 執行的。

```
@startuml
skinparam backgroundColor #EEEBDC
skinparam handwritten false

actor "駕駛 (User)" as User
participant "Flutter App\n(UI + Riverpod)" as App
participant "Keycloak\n(Auth Server)" as Keycloak
participant "你的後端 API\n(Token Service)" as Backend
participant "LiveKit Server" as LiveKit
participant "STT Agent\n(AI 語音轉字)" as Agent

== 1. 登入階段 (Authentication) ==
User -> App : 打開 App
App -> App : 檢查 SecureStorage
alt 無有效 Token
    App -> Keycloak : 請求登入 (AppAuth)
    User -> Keycloak : 輸入帳密
    Keycloak --> App : 回傳 Access Token & Refresh Token
    App -> App : 存入 SecureStorage
end
App --> User : 顯示首頁 (輸入房間名稱)

== 2. 建立連線 (Connection Handshake) ==
User -> App : 輸入 Room ID 並點擊「通話」
App -> Backend : POST /get-token\n(Header: Bearer Keycloak_Access_Token)
note right of App
  帶著 Keycloak 的 Token
  證明我是合法用戶
end note

activate Backend
Backend -> Keycloak : (可選) 驗證 Token 有效性
Backend -> Backend : 生成 LiveKit Room Token\n(給予 driver_mic 權限)
Backend --> App : 回傳 LiveKit Token
deactivate Backend

App -> LiveKit : Connect(LiveKit Token)
activate LiveKit
LiveKit --> App : 連線成功 (Connected)
deactivate LiveKit

App -> App : 開啟麥克風
App --> User : 進入通話畫面 (左右分割)

== 3. 通話與逐字稿 (Streaming & Data) ==
par 音訊傳輸
    User -> App : 說話 (Voice)
    App -> LiveKit : Publish Audio Track
    LiveKit -> Agent : Audio Stream
end

par 逐字稿處理
    Agent -> Agent : 語音轉文字 (STT)
    Agent -> LiveKit : Publish Data (JSON: "你好...")
    LiveKit -> App : OnDataReceived (Data Packet)
    App -> App : Riverpod 更新逐字稿 List
    App --> User : UI 顯示文字泡泡
end

== 4. 聲道控制 (Native Control) ==
User -> App : 點擊 "切換左聲道"
App -> App : 呼叫 MethodChannel\n(Android AudioManager)
App -> App : 設定 setStereoVolume / setBalance
App --> User : 聲音集中在左側喇叭

== 5. 結束通話 ==
User -> App : 點擊 "掛斷"
App -> LiveKit : Disconnect
LiveKit --> App : 斷線確認

@enduml

```
