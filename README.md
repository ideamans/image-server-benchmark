# 画像配信 Web サーバー ベンチマーク

異なる言語・フレームワークで実装された画像配信サーバーの性能を比較するベンチマークツールです。

## 概要

このプロジェクトでは、以下の 9 つの Web サーバーフレームワークの性能を比較します：

### 対象フレームワーク

| 言語       | フレームワーク | ポート |
| ---------- | -------------- | ------ |
| TypeScript | Fastify        | 3001   |
| TypeScript | Hono           | 3002   |
| TypeScript | Elysia (Bun)   | 3003   |
| Go         | Fiber          | 3004   |
| Go         | Gin            | 3005   |
| Go         | Echo           | 3006   |
| Rust       | Actix-web      | 3007   |
| Rust       | Axum           | 3008   |
| Rust       | Rocket         | 3009   |

### テストケース

各サーバーは以下の 6 つのエンドポイントを実装しています：

- **ローカル画像配信**

  - `/local/20k` - 20KB の画像
  - `/local/50k` - 50KB の画像
  - `/local/100k` - 100KB の画像

- **プロキシ画像配信**（S3 からの画像取得）
  - `/proxy/20k` - 20KB の画像
  - `/proxy/50k` - 50KB の画像
  - `/proxy/100k` - 100KB の画像

## 前提条件

### 必要なソフトウェア

- Docker および docker-compose
- または以下の開発環境：
  - Node.js 18 以上
  - Go 1.21
  - Rust（最新版）
  - Bun（最新版）
  - k6（ベンチマークツール）

### AWS環境（CDKでEC2をプロビジョニングする場合）

- AWS CLI がインストールされ、設定済みであること
- AWS CDK がインストールされていること（`npm install -g aws-cdk`）
- EC2キーペアが作成済みであること

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/idaemans/image-server-benchmark.git
cd image-server-benchmark
```

### 2. 環境設定ファイルの準備

```bash
# .envファイルをコピー
cp .env.example .env

# .envファイルを編集
vim .env
```

#### 重要な設定項目

```env
# プロキシテスト用のS3バケットURL（必須）
# 末尾のスラッシュ必須。20k.jpg, 50k.jpg, 100k.jpgを配置しておく
ORIGIN_URL_BASE=https://your-bucket.s3.amazonaws.com/images/

# ベンチマーク実行時のサーバーIP（デフォルト：localhost）
SERVER_IP=localhost

# ベンチマーク設定（開発用の短時間設定例）
MAX_VUS=10                    # 仮想ユーザー数
BENCHMARK_DURATION=5s         # メインテスト時間
BENCHMARK_WARMUP_DURATION=2s  # ウォームアップ時間
BENCHMARK_COOLDOWN_DURATION=3s # クールダウン時間

# 本番ベンチマーク用の設定例
# MAX_VUS=200
# BENCHMARK_DURATION=60s
# BENCHMARK_WARMUP_DURATION=10s
# BENCHMARK_COOLDOWN_DURATION=10s
```

### 3. Amazon Linux 2023 環境での実行（推奨）

最も簡単な方法です。Docker を使用して Amazon Linux 2023 環境を構築します。

```bash
# Dockerコンテナを起動して入る
./run-amazon-linux.sh

# コンテナ内で環境構築（初回のみ、5-10分程度）
./setup-amazon-linux.sh

# サーバーをすべて起動
./start-servers.sh

# 別のターミナルを開いて、同じコンテナに入る
docker-compose exec benchmark-server bash

# ベンチマークを実行
./run-benchmark.sh
```

### 4. ローカル環境での実行（上級者向け）

#### macOS の場合

```bash
# 依存関係のインストール
brew install node go rust k6
curl -fsSL https://bun.sh/install | bash

# プロジェクトのセットアップ
make clean
make build-release

# サーバーの起動
./start-servers.sh

# 別のターミナルでベンチマーク実行
./run-benchmark.sh
```

## テスト画像の準備

### ローカル画像

プロジェクトに含まれるスクリプトで生成します：

```bash
cd images
./generate-images.sh
```

### プロキシ用画像（S3）

S3 バケットに以下の画像をアップロードしてください：

```bash
# AWS CLIを使用する場合
aws s3 cp images/20k.jpg s3://your-bucket/images/20k.jpg
aws s3 cp images/50k.jpg s3://your-bucket/images/50k.jpg
aws s3 cp images/100k.jpg s3://your-bucket/images/100k.jpg

# パブリックアクセスを許可
aws s3api put-object-acl --bucket your-bucket --key images/20k.jpg --acl public-read
aws s3api put-object-acl --bucket your-bucket --key images/50k.jpg --acl public-read
aws s3api put-object-acl --bucket your-bucket --key images/100k.jpg --acl public-read
```

## AWS CDKでEC2環境を構築する場合

### CDKのセットアップ

```bash
# .envファイルでAWSプロファイルを指定（オプション）
echo "AWS_PROFILE=myprofile" >> .env

# キーペア名を設定
echo "KEY_PAIR_NAME=benchmark-key" >> .env

# CDKディレクトリに移動
cd provisioning-cdk
npm install

# 初回のみ：CDKブートストラップ
npx cdk bootstrap

# スタックのデプロイ
./deploy.sh

# または手動で実行
npx cdk deploy --parameters KeyPairName=benchmark-key
```

### デプロイ後の作業

CDKの出力から、サーバーとクライアントのIPアドレスを確認し、SSHで接続します：

```bash
# サーバーインスタンスに接続
ssh -i ~/.ssh/benchmark-key.pem ec2-user@<server-ip>

# リポジトリがすでにクローンされているので
cd image-server-benchmark
./setup-amazon-linux.sh
./start-servers.sh

# クライアントインスタンスに接続（別ターミナル）
ssh -i ~/.ssh/benchmark-key.pem ec2-user@<client-ip>

cd image-server-benchmark
./setup-amazon-linux.sh
echo "SERVER_IP=<server-private-ip>" >> .env
./run-benchmark.sh
```

## ベンチマークの実行

### 基本的な実行

```bash
# すべてのサーバーが起動していることを確認
curl http://localhost:3001/health
curl http://localhost:3009/health

# ベンチマークを実行
./run-benchmark.sh
```

### 特定のサーバーのみテスト

```bash
# k6を直接使用する例
cd k6
k6 run -e SERVER_IP=localhost -e CURRENT_SERVER_PORT=3001 -e CURRENT_ENDPOINT=/local/20k benchmark.js
```

## 結果の確認

ベンチマーク実行後、以下のファイルが生成されます：

- `results/benchmark-results.tsv` - TSV 形式の結果
- `results/benchmark-results-detailed.json` - 詳細な JSON 形式の結果

### 結果の見方

実行後、以下のようなランキングが表示されます：

```
--- Local 20KB Image ---
Rank  Framework    Language     RPS      Avg RT    P95 RT    Error%
----  -----------  ----------   -------  --------  --------  ------
1     Fiber        Go           848.01    0.59ms    1.78ms    0.00
2     Gin          Go           844.54    0.72ms    2.42ms    0.00
3     Axum         Rust         837.56    0.95ms    2.79ms    0.00
...
```

- **RPS**: Requests Per Second（1 秒あたりのリクエスト数）
- **Avg RT**: 平均レスポンスタイム
- **P95 RT**: 95 パーセンタイルレスポンスタイム
- **Error%**: エラー率

## トラブルシューティング

### サーバーが起動しない

```bash
# ログを確認
./start-servers.sh

# 個別にサーバーを起動してエラーを確認
cd servers/typescript/fastify
npm start
```

### ベンチマークでエラーが出る

```bash
# .envの設定を確認
cat .env

# サーバーが起動しているか確認
./stop-servers.sh
./start-servers.sh

# ヘルスチェック
for port in {3001..3009}; do
  echo "Port $port: $(curl -s http://localhost:$port/health)"
done
```

### Rust のビルドエラー（openssl-sys）

Amazon Linux の場合：

```bash
dnf install -y openssl-devel pkg-config
```

macOS の場合：

```bash
brew install openssl pkg-config
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
```

### k6 が command not found エラー

```bash
# macOS
brew install k6

# Linux
sudo dnf install -y https://dl.k6.io/rpm/repo.rpm
sudo dnf install -y k6
```

## メンテナンス

### サーバーの停止

```bash
./stop-servers.sh
```

### ビルド成果物のクリーンアップ

```bash
./clean-servers.sh
```

### Docker コンテナの削除

```bash
docker-compose down
```

## パフォーマンスチューニング

本番環境でのベンチマークを行う場合は、以下の設定を調整してください：

### .env ファイル

```env
# 本番用設定
MAX_VUS=200
BENCHMARK_DURATION=60s
ERROR_THRESHOLD=0.01
RESPONSE_TIME_THRESHOLD=1000
```

### システム設定（Linux）

```bash
# ファイルディスクリプタの上限を増やす
ulimit -n 65536

# TCPパラメータの調整
sudo sysctl -w net.core.somaxconn=65535
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=65535
```

## ライセンス

MIT License

## 貢献

Issues や Pull Requests を歓迎します。

## 参考リンク

- [k6 ドキュメント](https://k6.io/docs/)
- [各フレームワークの公式ドキュメント]
  - [Fastify](https://www.fastify.io/)
  - [Hono](https://hono.dev/)
  - [Elysia](https://elysiajs.com/)
  - [Fiber](https://gofiber.io/)
  - [Gin](https://gin-gonic.com/)
  - [Echo](https://echo.labstack.com/)
  - [Actix-web](https://actix.rs/)
  - [Axum](https://github.com/tokio-rs/axum)
  - [Rocket](https://rocket.rs/)
