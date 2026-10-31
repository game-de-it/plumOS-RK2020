# サムネイルのscraping

[English](scraping.md) | [取扱説明書](README.ja.md)

scrapingはfrontendに表示済みのROMに対応する画像をdownloadします。

1. Wi-Fiへ接続し、Internet接続を確認します。
2. ROM file名を確認します。無関係なtagや長い注記がないgame名ほど一致しやすく
   なります。
3. `START -> Apps -> Scraping`を開きます。
4. systemとdownload種類を選び、開始します。
5. 結果画面が出るまで電源を維持します。

download画像はuser volumeへ保存され、graphic・gallery表示で使われます。画像が
見つからなくてもgame起動には影響しません。runtime indexを手作業で変えず、ROM名を
修正して再実行してください。

多数systemのscrapingには時間と書き込み容量が必要です。安定した電源と空き容量を
用意し、実行中はsleepやWi-Fi取り外しを行わないでください。
