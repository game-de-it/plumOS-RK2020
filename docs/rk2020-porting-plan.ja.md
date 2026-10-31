# RK2020移植計画

[English](rk2020-porting-plan.md)

日付: 2026-10-25

## source baseline

code baselineには、継続管理されているRK3326 portの中で最も近いplumOS Pixel2を
使用します。update、storage、frontend、emulator、serviceの設計は再利用できますが、
Pixel2のDTB、kernel ABI、panel geometry、controller identity、電源試験結果、実機
合格結果はRK2020へ流用しません。

元のPixel2 documentはprovenanceのため、書き換えず`docs/reference/pixel2/`へ保持
します。

## 作業単位とcommit方針

1. hardware合格を主張せず、再利用可能codeと名称をRK2020へ変更する。
2. stock boot/runtimeを読み取り専用で収集し、artifactとして登録する。
3. bootとkernel-runtime contractをRK2020 artifactへ置き換える。
4. display、input、audio、network、storage、power policyを適合させる。
5. seed imageをbuildし、host上でverifyする。
6. 別のSDカードで各実機subsystemを検証し、結果を記録する。

各単位を個別にcommitします。vendor binary、元SD image、secret、ROM、BIOS、save、
生成imageはGitへ含めません。

## safety boundary

起動中のstock cardは開発対象ではなく、調査証跡です。`/flash`は読み取り専用を維持
します。deviceを変更するcommandは、別のtest SDとrollback手順を用意してから実行
します。
