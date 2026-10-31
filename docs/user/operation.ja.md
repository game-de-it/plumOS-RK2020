# RK2020の操作、電源、エミュレータhotkey

[English](operation.md) | [取扱説明書](README.ja.md)

RK2020には音量ボタンがなく、アナログスティックの押し込みもありません。物理L2は
plumOSのFunction modifierも兼ねます。他機種向けのボタン説明をそのまま使わないで
ください。

## フロントエンド操作

| ボタン | 動作 |
| --- | --- |
| 十字キーまたはアナログスティック | カーソル移動 |
| A | 決定、開く、ゲーム起動 |
| B | 戻る、キャンセル |
| X | ROMリストとギャラリーを切り替える |
| Y | 対応画面でお気に入り登録・解除 |
| START | STARTメニューを開く |
| SELECT | 選択中ゲームの起動方法・coreを選ぶ |
| L2 / Function | frontend screenshotを`Screenshots/`へ保存 |
| 電源 | 電源メニューを開く |

グラフィック表示とテキスト表示は`START -> UI Settings`で選びます。システムの
ROM画面でXを押すとギャラリーへ切り替わります。

## システムhotkey

次の組み合わせはfrontendでもゲーム中でも使用できます。

| 組み合わせ | 動作 |
| --- | --- |
| L2 + 十字キー上／下 | 音量を上げる／下げる |
| L2 + 十字キー左／右 | 画面を暗くする／明るくする |

最初の音量段階は小さな音から始まるように調整されています。イヤホンを挿すと
speakerは自動でmuteされ、抜くとspeakerへ戻ります。

## 電源とスリープ

電源ボタンを短く押すとplumOS電源メニューが開きます。Aで決定、Bでキャンセル
します。Sleep、Restart、Shutdownは必ずこのメニューから実行してください。
save中やshutdown中に電源やSDカードを抜かず、処理が終わるまで待ちます。sleep
復帰は電源ボタンをもう一度押します。画面復帰後、Wi-Fi再接続まで10秒ほどかかる
場合があります。

USB電源の有無でRK2020の充電画面の挙動が変わります。shutdown後に画面とLEDが
安定してからケーブルを抜いてください。

## エミュレータmenu・終了操作一覧

表の「L2 / Function」は物理L2ボタンです。menuを開くだけでは正常終了になりません。
表示されたQuit／Exit項目を選んでください。

| 起動方法 | menu・特殊操作 | frontendへ戻る |
| --- | --- | --- |
| RetroArch | SELECT + BでQuick Menu表示／非表示 | START + SELECT |
| PicoArch | L2 + START | PicoArch menuのQuitを選ぶ |
| PCSX-ReARMed standalone | L2 + START | emulator menuのExitを選ぶ |
| PPSSPP standalone | L2でpause menu | Exit to menuを実行し、続けてExit |
| Mupen64Plus standalone | L2短押しでanalog stick／N64 D-pad mode切替 | L2を1.5秒長押し |
| DraStic standalone | L2 + STARTで統合menu、L2 + SELECTでDraStic native menu | どちらかのmenuでExit |
| OpenBOR standalone | L2でOpenBOR menuを開く／戻る | menuのExitを選ぶ |
| PICO-8 runtime | STARTでPICO-8 pause menu | runtimeのExit／Quitを選ぶ |

その他のstandalone programは、それぞれのmenuにあるExitを使用します。menu操作が
分からないという理由だけで強制電源断しないでください。ゲームへ戻るだけなら、
まず電源ボタンで電源menuを開き、Bでキャンセルできます。

## DraSticのtouch・画面操作

| 組み合わせ | 動作 |
| --- | --- |
| R2 | 通常modeで上下DS画面をswap |
| L2 + A | もう1つのDS画面layoutへ切り替え |
| L2 + X | 通常操作／touch cursor mode切り替え |
| analog stickまたは十字キー | touch modeでstylus cursor移動 |
| A | 選択位置をtouch |
| Rを押しながら移動 | cursorの微調整 |

L2 + Xをもう一度押すと通常操作へ戻ります。DraStic内でもL2 + 十字キーはsystem
音量・明るさ専用です。

## RetroArch shortcut

| 組み合わせ | 動作 |
| --- | --- |
| SELECT + B | Quick Menu表示／非表示 |
| START + SELECT | 正常終了してfrontendへ戻る |
| SELECT + L／R | state load／save |
| SELECT + 十字キー左／右 | 前／次のstate slot |
| SELECT + X | screenshot |
| SELECT + Y | FPS表示切り替え |
| SELECT + L2／R2 | slow motion／早送り切り替え |

保存場所とbutton番号は[RetroArchのセーブとhotkey](retroarch-saves-and-hotkeys.ja.md)
を参照してください。
