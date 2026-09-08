# AZTEC3 — 翡翠の手帳と太陽の記憶

チチェン・イッツァを舞台にした、Godot製のオリジナル・パズルアドベンチャー。3か所・3問の体験版です。資料を観察し、人物と話し、証拠を結びつけて展示の誤解を解きます。

**[ブラウザーで遊ぶ](https://kg-ninja.github.io/mayasensei/web/)** · **[Windows版](https://kg-ninja.github.io/mayasensei/downloads/AZTEC3-windows.zip)** · **[Linux版](https://kg-ninja.github.io/mayasensei/downloads/AZTEC3-linux.zip)**

## 遊び方

- クリック／タップで調査。Tabで選択、Enter／Spaceで決定。Nで手帳、Escで戻る。
- 札や証拠を選んで、置きたい枠を選択。ドラッグ操作は不要です。
- 各問題に3段階のヒント、リセット、解答と解説があります。解答を見ても最後まで進めます。長いヒントは枠内をスクロールできます。
- 途中配置、会話、証拠、ヒント、音と調査点の設定は自動保存。ブラウザー版は同じブラウザー・同じURLで再開してください。保存禁止・プライベートモード・サイトデータの削除等では保持されない場合があります。
- 新しく始めるときはタイトルの「はじめから」。確認後に現在の進行を上書きします。

PC版はZIPを展開して実行します。Linuxで実行権限が保持されなかった場合は `chmod +x AZTEC3.x86_64`。Windowsの実行ファイルはコード署名なしです。アーカイブのSHA256は [downloads/manifest.json](https://kg-ninja.github.io/mayasensei/downloads/manifest.json) に記録します。

## 実装・再ビルド

Godot **4.7.2 Standard / GDScript / Compatibility**。Webは単一スレッド・WebGL 2.0。実行時の有料API・会話AI・オンライン問題生成・アカウントは使いません。音も画面情報を読むための必須条件ではありません。

`aztec3/project.godot` をGodotで開き、実行できます。3問のResource定義は `aztec3/content/`、正解判定は `scripts/rules.gd`、進行と保存は `game_state.gd`・`save_service.gd`。セーブは `user://aztec3-v1.json` と直前の正常データ `.bak` です。

```powershell
# 標準のエクスポートテンプレートを導入済みの場合
./scripts/build.ps1 -Godot 'C:/path/to/godot.exe' -Python python
# Steam同梱など別のテンプレートを指定する場合
./scripts/build.ps1 -Godot 'C:/path/to/godot.exe' -TemplatesDirectory 'C:/path/to/4.7.2.stable' -Python python
```

スクリプトはインポート・型/構文解析・回帰検証・Web/Windows/Linuxの書き出し・ZIPのCRC確認を行います。指定したテンプレートパスは終了時に設定から戻します。

```text
godot --headless --path aztec3 --script res://tests/run.gd
AZTEC3.exe --headless -- --verify
AZTEC3.x86_64 --headless -- --verify
```

配布済みWebと同じコードの回帰確認は `web/?verify=1`。テストは専用セーブを使用します。PC版の `-- --ui-verify` は画面を表示してボタン操作から結末まで進み、実行ファイルの隣の `ui-captures/` に2解像度の画像を保存します。これは開発検証用です。

Webは `python -m http.server 4190` 等でリポジトリのルートから配信し、`http://localhost:4190/web/` を開きます。HTMLの直接ダブルクリックでは動作しません。

## 検証と範囲

検証記録は [docs/verification.json](https://github.com/KG-NINJA/mayasensei/blob/maya-mystery-caracol-4369826665362574781/docs/verification.json)。ソースの検証と配布ビルドの実行、目視確認、公開確認を分けて記録します。初見5人によるプレイテストは未実施で、面白さ・難度・所要時間を実測済みとは扱いません。18問の本編とスマートフォン実機対応は含みません。

背景・人物・図版・音は本作用のオリジナル。チチェン・イッツァはマヤの都市であり、AZTEC3は作品名です。登場人物・事件・施設・手帳・図版は創作で、実在の装置や測量結果ではありません。[史実の参照先](https://github.com/KG-NINJA/mayasensei/blob/maya-mystery-caracol-4369826665362574781/docs/historical_sources.md) · [素材台帳](https://github.com/KG-NINJA/mayasensei/blob/maya-mystery-caracol-4369826665362574781/docs/asset_licenses.csv) · [Godotとフォントのライセンス](https://github.com/KG-NINJA/mayasensei/tree/maya-mystery-caracol-4369826665362574781/licenses/)

以前のMaya Mystery – Caracolは [legacy.html](https://kg-ninja.github.io/mayasensei/legacy.html) と既存の `game.js`・`style.css`・`assets/` を維持しています。AZTEC3の本体へ旧素材は転用していません。
