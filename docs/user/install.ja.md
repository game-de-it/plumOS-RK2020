# インストールと初回起動

[English](install.md) | [取扱説明書](README.ja.md)

## 必要なもの

- RK2020本体
- 信頼できるmicroSDカード
- card readerとRaspberry Pi Imagerなどのraw image writer
- 必要に応じて対応USB Wi-Fi adapter

書き込み先SDカードに必要なファイルがある場合は、先にすべてbackupしてください。
image書き込みはpartition tableとsystem領域を置き換えます。

## イメージを書き込む

1. 配布imageが圧縮されている場合は展開します。
2. writerでplumOS RK2020 imageを選びます。
3. 容量とdevice名を確認してmicroSDカードを選びます。Macやbackup diskを選ばないで
   ください。
4. 書き込みとverifyを完了し、安全に取り外します。
5. 電源を切ったRK2020へ挿し、電源を入れます。

Raspberry Pi Imager、`dd`、Balena Etcherなどのraw writerは通常、image内に含まれる
sectorを書き換えます。大容量カードの後方sectorを必ずすべて消去するわけでは
ありません。

## 初回起動

初回起動では書き込み可能partitionを準備し、setup画面を表示します。低速SDでは
時間がかかります。frontendが表示されるまで電源を維持し、SDカードを抜かないで
ください。

対応USB adapterを使う場合だけWi-Fi setupを行います。adapterがない、または非対応の
場合は`MISSING`と表示されますが、offline利用は可能です。

## 再書き込み後に以前のファイルが見える場合

新imageが同じFAT user volume位置を使い、その領域をformatしなかった場合、以前の
ROMが再び見えることがあります。これはraw書き込みが一部sectorだけを上書きした
結果であり、backup・復旧機能ではありません。partition配置の変更、format、writer
設定、card障害、将来imageの大型化で消える可能性があります。必ず別媒体にもbackup
してください。詳細は[SDカードと再書き込み](storage-and-reimaging.ja.md)を参照して
ください。
