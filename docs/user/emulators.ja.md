# システムとエミュレータ

[English](emulators.md) | [取扱説明書](README.ja.md)

## ゲームを起動する

1. TOPでシステムを選びます。
2. ROMリストまたはギャラリーでゲームを選びます。
3. Aを押します。

起動前にSELECTを押すと、利用可能な起動方法を選べます。plumOSはそのシステムに
対応するprofileだけを表示し、install済みの全coreを全ROMへ候補表示しません。
非対応profileを無理に使うと最初のframeまで進まない場合があります。

## 起動方法の種類

- **RetroArch (RA)**: 最も広いsystemを扱い、Quick Menu、save state、shader、
  core別設定を利用できます。
- **PicoArch (PICO)**: 対応core向けの軽量な起動方法です。
- **Standalone (SA)**: PPSSPP、DraStic、PCSX-ReARMed、Mupen64Plus、OpenBOR、
  PICO-8などの専用programを使用します。

menuと終了buttonは起動方法ごとに異なります。
[エミュレータ操作一覧](operation.ja.md#エミュレータmenu終了操作一覧)を参照して
ください。

## ROMとBIOS

ゲームは`roms/`内のsystem別folderへ置きます。複数fileのCD gameはcue、track、
playlist、subfolderをまとめて保持してください。BIOSは`bios/`へ置き、emulatorが
指定する正確なfile名と大文字・小文字を維持します。arcade coreには対応ROM setが
必要です。

製品版PICO-8 runtimeは配布imageに含まれません。正規licenseを持つ場合はAArch64版を
次へ置きます。

```text
roms/pico-8/aarch64/
```

`pico8.dat`と、`pico8_64`など対応AArch64 executableが必要です。

## 性能と設定

一部のPSP、Nintendo 64、Dreamcast、arcade、software rendering titleはRK2020の
性能を超えます。低fpsが必ず設定不良とは限りません。設定は1項目ずつ変更し、同じ
場面で比較してください。

RA、PicoArch、standaloneの初期設定へ戻す場合は
`START -> System Settings -> Factory Reset`を使います。置き換える設定は先にbackup
されます。ROMや通常のsave dataは削除しません。
