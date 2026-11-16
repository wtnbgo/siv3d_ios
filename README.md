# siv3d_ios

OpenSiv3D (SDL3 版) で作ったアプリを **iOS (iPhone / iPad)** 向けにビルドするための案内と補助スクリプトです。

iOS 版のビルドの仕組み (CMake の Xcode ジェネレータ、vcpkg の iOS 用 triplet、`.app` バンドル、Info.plist の生成) は
すべて OpenSiv3D 側 (`cmake/Siv3DAppTarget.cmake` の `siv3d_add_app()` と `tools/siv3d_app.py`) にあります。
アプリはアプリのテンプレート [siv3d_app](https://github.com/wtnbgo/siv3d_app) のまま、`siv3d-app.json` の `"ios"` 節と
`make ios` でビルドできるので、このリポジトリに Xcode のプロジェクトなどは置いていません。

## 構成

```
work/
  OpenSiv3D/    ← develop_sdl3 ブランチ (SIV3D_BASE)
  MyApp/        ← siv3d_app から作ったアプリ
  siv3d_ios/    ← このリポジトリ (補助スクリプト)
```

## 必要なもの

- macOS と Xcode (iOS SDK、iOS シミュレータのランタイム)。確認済み: macOS 15.8 (Intel)、Xcode 26.3
- CMake 3.21 以上、Python 3.9 以上、vcpkg (環境変数 `VCPKG_ROOT`)
- 実機で動かす場合: Apple Developer の Team ID (アプリの `siv3d-app.local.json` の `ios.team`、または環境変数 `SIV3D_IOS_TEAM`)。確認済み: iPhone 11 (iOS 26.5)

## 使い方

```bash
cd MyApp
make ios          # シミュレータ向け (ホストの CPU: Intel Mac は x86_64、Apple Silicon は arm64) に build + stage + package
make ios-run      # 起動中のシミュレータ (無ければ iPhone を 1 台起動) にインストールして起動
make ios-device   # 実機 (arm64) 向け。build/ios/device-arm64/package/<exeName>-<version>-ios-device.ipa
make ios-device-run  # 接続中の実機にインストールして起動 (DEVICE=<UDID または名前> で選べる)
```

実機で動かすには Apple Developer の Team ID による署名が必要です。Team ID はアプリのフォルダの
`siv3d-app.local.json` (git の管理外) に `{ "ios": { "team": "..." } }` と書きます (環境変数 `SIV3D_IOS_TEAM` でも可)。
手順はテンプレート (siv3d_app) の README の「iOS 実機で動かす」を参照してください。

`siv3d-app.json` の例:

```json
"ios": {
  "displayName": "My App",
  "build": "1",
  "deploymentTarget": "15.0",
  "orientations": "landscape"
}
```

詳しい設定項目・しくみ・制限は OpenSiv3D の [`SDL3/BUILD-iOS.md`](https://github.com/wtnbgo/OpenSiv3D/blob/develop_sdl3/SDL3/BUILD-iOS.md) を参照してください。

## 補助スクリプト

| スクリプト | 内容 |
|---|---|
| `scripts/sim.sh list` | 利用できる iPhone / iPad のシミュレータの一覧 (状態と UDID) |
| `scripts/sim.sh boot <名前または UDID>` | シミュレータを起動して Simulator.app を開く (`make ios-run` はこれで起動したものを使う) |
| `scripts/sim.sh log <バンドル ID>` | 起動中のシミュレータでアプリを起動し直し、標準出力 (Siv3D のログ) を表示する |
| `scripts/sim.sh shot <ファイル>` | 起動中のシミュレータのスクリーンショットを保存する |
| `scripts/sim.sh reset` | 応答しなくなったシミュレータのサービス (CoreSimulatorService) を再起動する |

## 制限 (iOS 版)

- ファイルダイアログ、DirectoryWatcher、テキストエディタ・ファイルマネージャの起動は使えません
- WebM の動画 (movie-player) は使えません (libvpx が iOS シミュレータ向けにビルドできないため)
- 描画は OpenGL ES (EAGL)。シミュレータでは Apple のソフトウェアレンダラになります
- ライセンス一覧はブラウザでは表示できないので、アプリ内に表示します (テンプレートの `LicenseView.hpp` と [Licenses] ボタン)
- ソフトウェアキーボードは、入力欄が入力中の間だけ出ます (SimpleGUI の `TextBox` / `TextArea` は自動。独自の入力欄は入力中の間 `TextInput::SetEditingArea` を毎フレーム呼ぶ)。
  外をタップすると閉じ、閉じた後はもう一度タップで出し直します。**シミュレータでは、ソフトウェアキーボードの ⌫ が効きません**
  (SDL が、Mac のキーボードが接続されている (`SDL_HasKeyboard()`) とみなして BS を捨てるため。実機での確認と SDL の修正は今後の検討事項)
- iOS では終了要求で終了しません (アプリの終了は OS に任せます)。`System::Exit()` も呼ばないでください (画面が黒いまま残ります)

## 確認状況

- iOS シミュレータ (Intel Mac の x86_64、iOS 26.3 / 18.5): テンプレートの MyApp の表示 (画像・文字)、音声、アプリ内のライセンス一覧、
  ソフトウェアキーボードの開閉と文字入力 (上の ⌫ を除く)
- 実機 (iPhone 11、iOS 26.5): 署名付きでビルドしてインストール・起動し、画像と文字が表示されることを確認
  (描画は Apple A13 GPU の OpenGL ES 3.0、音声は MiniAudio)。ソフトウェアキーボードでの文字入力は、実機では未確認
