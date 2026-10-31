# Wi-Fi、SFTP、時刻

[English](network.md) | [取扱説明書](README.ja.md)

RK2020に内蔵Wi-Fiはありません。対応USB Wi-Fi adapterを接続してから
`START -> Network Settings`を開きます。

## Wi-Fi setup

1. Wi-FiをONにします。
2. networkをscanし、SSIDを選びます。
3. passwordを入力して接続します。
4. top barにWi-Fiが表示され、Network SettingsでIP addressを確認できることを
   確認します。

`MISSING`は対応network interfaceが存在しない状態です。stock EmuELECで動くdongleが
必ずplumOSでも動くとは限らず、chipsetとdriverの対応が必要です。本体電源OFF中に
adapterを挿し直してから起動してください。書き込み中やsleep移行中に何度も抜き差し
しないでください。

sleep中はWi-Fiへの給電を止め、復帰後に再接続します。復旧完了まで約10秒、adapter
LEDが消えたままになる場合があります。

## SFTP file転送

FileZillaなどのSFTP clientを次のように設定します。

```text
Protocol: SFTP
Host:     plumOSに表示されたIP address
Port:     22
User:     root
Password: plumos
```

passwordは小文字で、大文字・小文字を区別します。ROMは`/mnt/plumos-user/roms/`、BIOSは
`/mnt/plumos-user/bios/`へ置きます。update inputはrelease手順で指定された場所だけを
使います。SFTPから`/mnt/plumos/`のruntime fileを変更しないでください。

default root passwordは信頼できるlocal network向けです。Internetからport 22へ
port forwardしないでください。

## 時刻

Automatic TimeをONにすると、network接続後に時刻を同期しhardware clockも更新します。
networkがない場合はSystem Settingsで日付、時刻、timezoneを手動設定します。
