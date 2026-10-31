# リリース手順

[English](release-process.md)

これはplumOS RK2020の公開契約です。最初の正式versionは**0.1.0**です。host buildの
成功はcandidate生成に過ぎず、圧縮配布imageそのものをRK2020実機で合格させてから
公開します。

## 事前条件

- 公開対象commitで全変更をcommitし、clean treeから作業します。
- 登録済みstock RK2020 boot prefixとruntime入力を`artifacts/`に用意します。これらは
  local build入力であり、source archiveには含めません。
- ROM、利用者BIOS、save、認証情報、proprietary PICO-8 runtime、mutable user stateが
  release入力に混入していないことを確認します。
- `v`なしの`0.1.0`をversion引数にします。release metadataには予定Git tagを
  `v0.1.0`として記録します。
- tag作成前に、既存`v0.1.0`が別projectや別commitを指していないことを確認します。
  現在のcheckoutにはlocal base remote由来のPixel2旧tagが残っているため、公開済みtagを
  暗黙に移動してはいけません。

## Buildとlocal gate

repository rootで実行します。

```sh
./scripts/prepare-rk2020-release.sh --version 0.1.0
```

このcommandはrelease imageを再buildし、source、implementation、content、license、
app-layer、System、image gateを実行します。さらにSD imageを2回連続生成してSHA-256の
完全一致を確認し、release bundleを生成・検証します。tag作成や公開は行いません。

他のplumOS機種と同じ規則で、次の名前を使います。

```text
dist/plumOS-RK2020-v0.1.0/
  plumOS-RK2020-v0.1.0-sd-image.7z
  plumOS-RK2020-v0.1.0-source.tar.gz
  LICENSE
  NOTICE.md
  THIRD_PARTY_NOTICES.md
  THIRD_PARTY_NOTICES.ja.md
  RELEASE_NOTES.md
  RELEASE_MANIFEST.json
  SHA256SUMS
```

`LICENSE`はplumOS作成部分だけに適用されます。stock boot由来のvendor fileと
third-party componentには、それぞれの条件が引き続き適用されます。境界と同梱証跡は
notice file、およびimage内のlicense bundleで確認できます。

bundleだけを再検証するcommand:

```sh
./scripts/verify-rk2020-release-bundle.py dist/plumOS-RK2020-v0.1.0
```

## 実機release acceptance

release `.7z`からstream展開した同一`.img`を別SDカードへ書き込み、SHA-256を記録して
次の実機matrixを確認します。

- cold boot、初回setup、partition拡張、2回目boot
- FE操作、POWER menu、shutdown、reboot、sleep、resume
- 画面geometry・色、入力、speaker・headphone audio、volume・brightness hotkey
- USB Wi-Fi、DHCP、resume後の再接続、SSH、SFTP
- 代表RetroArch、PicoArch、standalone emulator、App route
- 起動中の充電、cable接続時・未接続時のshutdown

writer完了、host verifier合格、frontendが1回起動したことだけでは、同一release assetの
実機acceptanceを代替できません。

## 公開境界

同一imageの実機合格後だけ、`RELEASE_MANIFEST.json`の`source_ref`へ`v0.1.0` tagを
作成し、`SHA256SUMS`記載fileと`SHA256SUMS`自体を全てuploadします。tag後にassetを
再buildしません。upload後は`verify-rk2020-release-bundle.py --download-base URL`で
保存されたassetを再download・検証します。
