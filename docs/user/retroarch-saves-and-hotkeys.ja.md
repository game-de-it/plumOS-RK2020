# RK2020 RetroArchの操作とhotkey

[English](retroarch-saves-and-hotkeys.md) | [本体操作](operation.ja.md)

## システムhotkey

| 物理ボタン | 動作 |
| --- | --- |
| L2 + 十字キー上／下 | 音量を上げる／下げる |
| L2 + 十字キー左／右 | 画面を暗くする／明るくする |

この組み合わせはEmuELECで確認されたRK2020の物理操作に合わせています。RK2020
にはOGA F2/MinusおよびF5/Plusに相当する物理ボタンはありません。

## RetroArch hotkey

ゲーム中のRetroArch hotkeyはSELECTをmodifierとして使用します。

| 物理ボタン | 動作 |
| --- | --- |
| SELECT + B | RetroArch Quick Menuを開く／閉じる |
| START + SELECT | RetroArchを終了してフロントエンドへ戻る |
| SELECT + L | ステートをロード |
| SELECT + R | ステートをセーブ |
| SELECT + 十字キー左／右 | 前／次のステートslot |
| SELECT + X | スクリーンショット |
| SELECT + Y | FPS表示切り替え |
| SELECT + L2 | スローモーション切り替え |
| SELECT + R2 | 早送り切り替え |

START + SELECTはRetroArchの通常終了経路を使うため、save RAMと終了時自動
ステートの書き込み完了を待ちます。

## RK2020のRetroArch button番号

RK2020のstock kernelが公開するevdev順序をRetroArchのudev driverへ次のように
変換します。

| 物理ボタン | evdev code | RetroArch udev button |
| --- | ---: | ---: |
| B | 304 | 0 |
| A | 305 | 1 |
| X | 307 | 2 |
| Y | 308 | 3 |
| L | 310 | 4 |
| R | 311 | 5 |
| 十字キー上／下／左／右 | 544／545／546／547 | 6／7／8／9 |
| SELECT | 704 (F1) | 10 |
| L2 | 706 (F3) | 12 |
| R2 | 707 (F4) | 13 |
| START | 709 (F6) | 15 |

button 11（F2）と14（F5）はscan順序には存在しますが、RK2020の物理ボタン
ではありません。

## 保存場所

標準ではsave RAMとsave stateをROM folder・core別に保存します。例えばQuickNESで
次のROMを起動した場合:

```text
roms/FC/Akumajou Densetsu.nes
```

保存先はおおむね次の構成になります。

```text
roms/FC/FC/QuickNES/
  Akumajou Densetsu.srm
  Akumajou Densetsu.state.auto
  Akumajou Densetsu.state.auto.png
```

save RAMは10秒ごとにflushします。save-state slotは自動indexされ、最大20世代と
thumbnailを保持します。終了時に自動ステートを保存しますが、次回起動時には自動で
loadしません。
