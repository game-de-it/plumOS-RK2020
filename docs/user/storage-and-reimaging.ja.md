# SDカードの保存領域と再書き込み

[English](storage-and-reimaging.md)

## パーティション構成

RK2020向け配布イメージはcompact seedです。イメージには`PLUMOS_BOOT`と
初期サイズの`PLUMOS_SYS`だけが含まれます。初回起動時に`PLUMOS_SYS`を
8 GiBへ拡張し、残りの領域をFAT32の`PLUMOS_USER`として準備します。

`PLUMOS_USER`にはROM、BIOS、画像、音楽、セーブなどの利用者データを置きます。

## 再書き込み後に以前のファイルが見える場合

同じSDカードへ新しいcompact imageを書いた後、転送していないROMが
`PLUMOS_USER`に再び表示される場合があります。これはPC側のファイル一覧cacheや、
配布イメージにROMが含まれているためではありません。

compact imageはSDカード全容量より短いため、通常はイメージ終端より後ろのsectorを
上書きしません。以前の`PLUMOS_USER`のFAT32 filesystemがそこに残り、初回起動時に
作成されるp3の開始位置と一致すると、plumOSは既存のFAT32を認識します。filesystemの
typeが`vfat`、labelが`PLUMOS_USER`であれば、初回setupはformatを省略し、必要な
directoryだけを追加して既存内容を再利用します。

パーティションtableは保存領域の開始位置と長さを示す「地図」です。tableが
イメージ書き込みで置き換わっても、後方のFAT、directory entry、file dataが
上書きされていなければ、同じ開始位置からp3を作ることで再び読める場合があります。

同じcompact-seed構成、固定されたuser partition開始位置、既存FATのpreserve policyを
採用する別のplumOS機種でも同様の現象は起こり得ます。ただし、各機種・各releaseで
partition geometryと初回setup実装が同一とは限らないため、シリーズ共通の保証では
ありません。

## データ保持機能ではありません

この挙動をbackupまたはrecovery機能として扱わないでください。次の場合は
`PLUMOS_USER`を再利用できない、または内容を失う可能性があります。

- 書き込みtoolがSDカード全体を消去、discard、またはzero fillした場合
- 新しいimageが以前の`PLUMOS_USER`領域まで上書きした場合
- release間でuser partitionの開始位置やfilesystem形式が変わった場合
- FAT32が破損した場合
- SDカード自体が故障した場合

また、`PLUMOS_SYS`は再書き込みされます。そこにあるRuntime状態や設定まで
`PLUMOS_USER`と同様に残ることを意味しません。

重要なROM、セーブ、BIOS、設定は別のstorageへbackupしてください。完全に空のSDとして
試験する場合は、イメージを書き込む前にカード全体を明示的に消去する必要があります。
全体消去は既存データを復元できなくするため、対象deviceを確認してから実施してください。
