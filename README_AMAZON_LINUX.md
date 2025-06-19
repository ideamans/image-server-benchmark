# Amazon Linux 2023 での実行方法

## Docker を使用した場合

```bash
# 1. Docker環境を起動して入る
./run-amazon-linux.sh

# 2. コンテナ内で実行
./setup-amazon-linux.sh

# 3. サーバーを起動
./start-servers.sh
```

## EC2 インスタンスの場合

```bash
# 1. リポジトリをクローン
git clone https://github.com/idaemans/image-server-benchmark.git
cd image-server-benchmark

# 2. セットアップを実行（これだけ！）
./setup-amazon-linux.sh

# 3. サーバーを起動
./start-servers.sh
```

## セットアップスクリプトが行うこと

`./setup-amazon-linux.sh` は以下をすべて自動で実行します：

1. システムパッケージの更新
2. 開発ツールのインストール（gcc, make等）
3. Rust用ライブラリのインストール（openssl-devel等）
4. Node.js と npm のインストール
5. Go 1.21 のインストール
6. Rust の最新版のインストール
7. Bun のインストール
8. k6（ベンチマークツール）のインストール
9. すべてのサーバー依存関係のインストール
10. k6スクリプトの依存関係のインストール
11. すべてのサーバーのビルド
12. PATH設定とシンボリックリンクの作成

## セットアップ後の使い方

### サーバーとして使う場合
```bash
./start-servers.sh
```

### クライアント（ベンチマーク実行）として使う場合
```bash
# .envファイルにサーバーIPを設定
echo "SERVER_IP=10.0.0.1" >> .env

# ベンチマークを実行
./run-benchmark.sh
```

## トラブルシューティング

### コマンドが見つからない場合

セットアップ完了後、新しいシェルを開いた場合：

```bash
source /etc/profile.d/benchmark.sh
```

### ビルドエラーが発生した場合

```bash
# ログを確認
make clean
make build-release
```

## 注意事項

- セットアップには5-10分程度かかります
- インターネット接続が必要です
- 十分なディスク容量（3GB以上）が必要です