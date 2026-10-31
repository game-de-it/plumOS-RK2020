# plumOS RK2020のアップデート

[English](updates.md) | [取扱説明書](README.ja.md)

現在のRK2020 releaseはSD imageを手動で書き換えてupdateします。System Update画面は
案内用です。他のplumOS機種向けupdate packageをinstallしないでください。

## 推奨手順

1. release noteを読み、imageがRK2020専用であることを確認します。
2. FAT user volume、特にROM、BIOS、save、state、screenshot、PortMaster data、
   正規PICO-8 runtimeをbackupします。
3. checksumが配布されている場合はdownload fileをverifyします。
4. plumOS電源menuからshutdownし、画面とLEDが安定してからSDを抜きます。
5. [インストール手順](install.ja.md)に従って新imageを書き込みます。
6. 初回起動を完了し、display、input、audio、Wi-Fi、sleep、代表game 1本を再確認して
   から他のdataを戻します。

新imageのpartition位置が同じ場合、以前のFAT dataがそのまま読めることがあります。
これは利便上の結果にすぎないため、backupを省略しないでください。

PortMasterには`START -> Apps -> Update PortMaster`という別のupdaterがあります。
これはPortMaster componentだけを更新し、plumOS本体は更新しません。
