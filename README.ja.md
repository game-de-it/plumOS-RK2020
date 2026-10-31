# plumOS RK2020

[English](README.md) | [移植計画](docs/rk2020-porting-plan.md) |
[SDカードと再書き込み](docs/user/storage-and-reimaging.ja.md) | [TODO](TODO.md)

RK3326搭載のRK2020へplumOSシリーズを移植するためのリポジトリです。
同じSoCで運用実績のあるplumOS Pixel2実装を出発点にしていますが、RK2020での
検証結果は独立して管理します。Pixel2の過去資料は
`docs/reference/pixel2/`へ隔離しており、RK2020の実機合格を意味しません。

## 現在の段階

現在は初期bring-upです。stock EmuELEC 4.8を読み取り専用で調査し、次の境界を
採用します。

- Rockchip boot prefix、stock `KERNEL`、stock DTB、4.4.189用module/firmwareは
  ハードウェア互換層として保持する。
- stock `SYSTEM`は解析入力に限定し、生成イメージへコピーしない。
- stock initramfsが`SYSTEM`をmountした後のPID 1、service、frontend、emulator、
  update機構はplumOSが所有する。
- stock SDは変更せず、起動試験は必ず別のSDカードで行う。

ホスト上のbuildやchecksum成功だけでは、実機のboot、320×480表示、入力、RK817
audio、充電・電源、USB Wi-Fi、全emulator routeの合格にはなりません。

## ライセンス

plumOS作成部分は[MIT License](LICENSE)です。stock/vendor boot materialと
third-party componentはそれぞれ元の条件を保持します。vendor binaryはgitへ
commitせず、ローカルの`artifacts/vendor/`で管理します。
