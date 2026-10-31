# トラブルシューティング

[English](troubleshooting.md) | [取扱説明書](README.ja.md)

## Wi-Fiが`MISSING`になる

電源を切り、USB adapterを確実に接続してから起動します。stock EmuELECで対応する
chipsetでもplumOSに同じdriverがない場合があります。既知の対応adapterを試して
ください。sleep復帰後は失敗と判断する前に約10秒待ちます。

## ROMが表示されない

system folderとextensionを確認し、UI SettingsからTOPを更新するかfrontendを再起動
します。複数file gameにはcue／playlistとtrackが必要です。空systemはdefaultで非表示
です。

## ゲームがすぐfrontendへ戻る

default起動方法を試し、必要BIOSのfile名とarcade ROM setの対応を確認します。install
されているという理由だけでPicoArchやstandaloneを選ばず、そのsystemとcontentに
対応するrouteを使ってください。

## menu・終了操作が分からない

[エミュレータ別一覧](operation.ja.md#エミュレータmenu終了操作一覧)を確認します。
RK2020にはstick押し込みと専用音量buttonがありません。L2はFunctionを兼ね、
十字キーとの組み合わせでsystem音量・明るさを変更します。

## sleep復帰・電源menu cancel後に画面が黒い

display ownerとWi-Fiが戻るまで数秒待ち、電源buttonを1回だけ押します。storage動作中に
連打や電源長押しをしないでください。音だけ続く場合は、emulator、USB cable有無、
audio、各LED状態を記録してください。これらは別々の診断情報です。

## 音が出ない・出力先が違う

L2 + 十字キー上で音量を上げます。イヤホンを一度抜き挿しし、挿入中だけspeakerが
muteされることを確認します。frontendとgameの音は別々に試験してください。

## shutdownとUSB電源

USB電源の有無で充電画面・LED挙動が変わります。必ず電源menuからshutdownし、最終
状態まで待ちます。shutdown後に充電画面へ入った場合は、強制resetではなく電源button
を短く1回押します。

## SD破損が疑われる

正常shutdown後、repair前に別PCでFAT volumeをbackupします。mount中・使用中のvolume
へrepair toolを実行しないでください。system復旧を再書き込み後の残存sectorへ依存
させず、新imageとuser data backupを別に保持します。

## emulator設定を初期化する

`START -> System Settings -> Factory Reset`でRA、PicoArch、standalone、またはallを
選びます。置き換える設定はbackupされます。runtime fileを手作業で削除するより安全
です。
