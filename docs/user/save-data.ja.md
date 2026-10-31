# セーブデータとbackup

[English](save-data.md) | [取扱説明書](README.ja.md)

save dataはFAT user volumeへ書き込みます。RetroArchは通常、ROM folder・core別の
directoryへsave RAMとstateを保存します。standalone emulatorも同じuser storage
内の専用directoryを使用します。

## 安全に保存する

- emulatorの通常Quit／Exit操作で終了します。
- game内save後はshutdownまで数秒待ちます。
- plumOS電源menuからshutdownし、LEDや進捗画面が動作中の間はSDを抜きません。
- 複数fileのdisc gameは一部fileだけをrenameしません。

RetroArchはsave RAMを10秒ごとにflushし、正常終了時にauto stateを書き込みます。
次回起動時にauto stateを自動loadはしません。

## backup

FAT volumeの`roms/`、`bios/`、save/state directory、screenshot、PortMaster・PICO-8
user fileを少なくともbackupしてください。個別fileを選ぶより、user volume全体を
copyした方が復旧しやすくなります。

image再書き込み後も以前のFAT dataが読める場合がありますが、backup機能では
ありません。[SDカードと再書き込み](storage-and-reimaging.ja.md)も参照してください。
