# 画像配信 Web サーバー ベンチマーク

AI によって生成した、異なる言語・フレームワークで実装された画像配信サーバーの性能を比較するベンチマークツールです。

## 結果

ベンチマークは AWS EC2 インスタンス同士で行いました。

- サーバー `t3.small`
- k6 クライアント ``m7i.2xlarge`
- ローカルネットワーク接続

```
=== Benchmark Summary - Performance Rankings ===

--- Local 20KB Image ---
Rank  Framework    Language     RPS      Avg RT    P95 RT    Error%
----  -----------  ----------   -------  --------  --------  ------
1     Fiber        Go           7257.29      1.68ms      6.81ms    0.00
2     Gin          Go           7064.58      2.11ms      7.33ms    0.00
3     Echo         Go           6500.14      3.20ms     11.86ms    0.00
4     Hono         TypeScript   3707.23     14.20ms     29.38ms    0.00
5     Axum         Rust         3384.95     17.20ms     56.65ms    0.00
6     Rocket       Rust         3308.62     17.54ms     57.45ms    0.00
7     Fastify      TypeScript   2289.01     29.72ms     67.14ms    0.00
8     Actix        Rust          940.73     87.86ms    307.63ms    0.00

--- Local 50KB Image ---
Rank  Framework    Language     RPS      Avg RT    P95 RT    Error%
----  -----------  ----------   -------  --------  --------  ------
1     Fiber        Go           5033.06      5.63ms     21.34ms    0.00
2     Gin          Go           4959.71      5.93ms     22.34ms    0.00
3     Echo         Go           4926.57      6.04ms     22.89ms    0.00
4     Hono         TypeScript   2950.53     19.96ms     50.66ms    0.00
5     Fastify      TypeScript   2056.70     33.75ms     80.42ms    0.00
6     Rocket       Rust          386.70    230.18ms    754.77ms    0.00
7     Axum         Rust          386.51    229.83ms    706.69ms    1.00
8     Actix        Rust          381.38    230.91ms    737.35ms    1.00

--- Local 100KB Image ---
Rank  Framework    Language     RPS      Avg RT    P95 RT    Error%
----  -----------  ----------   -------  --------  --------  ------
1     Fiber        Go           2784.44     15.10ms     47.14ms    0.00
2     Gin          Go           2769.12     15.88ms     49.86ms    0.00
3     Echo         Go           2759.48     15.93ms     49.09ms    0.00
4     Hono         TypeScript   2195.27     28.26ms     70.18ms    0.00
5     Fastify      TypeScript   1503.83     48.72ms    102.34ms    0.00
6     Axum         Rust          171.83    505.34ms   1592.70ms    2.00
7     Rocket       Rust          170.95    516.56ms   1554.66ms    7.00
8     Actix        Rust          166.63    505.44ms   1543.72ms    9.00

--- Proxy 20KB Image ---
Rank  Framework    Language     RPS      Avg RT    P95 RT    Error%
----  -----------  ----------   -------  --------  --------  ------
1     Gin          Go           2388.58     28.09ms     45.32ms    0.00
2     Fiber        Go           2376.08     28.26ms     47.88ms    0.00
3     Echo         Go           2310.39     29.42ms     48.95ms    0.00
4     Hono         TypeScript   1118.24     72.15ms    148.65ms    0.00
5     Fastify      TypeScript    971.17     84.69ms    161.79ms    0.00
6     Actix        Rust           55.30   1698.96ms   3521.80ms    0.00
7     Rocket       Rust           53.26   1769.17ms   4438.05ms    0.00
8     Axum         Rust           51.23   1843.31ms   4184.50ms    0.00

--- Proxy 50KB Image ---
Rank  Framework    Language     RPS      Avg RT    P95 RT    Error%
----  -----------  ----------   -------  --------  --------  ------
1     Gin          Go           2251.96     29.95ms     50.00ms    0.00
2     Fiber        Go           2194.17     30.96ms     50.56ms    0.00
3     Echo         Go           1641.26     46.00ms     59.90ms    0.00
4     Hono         TypeScript    897.44     92.17ms    181.68ms    0.00
5     Fastify      TypeScript    893.69     92.60ms    174.01ms    0.00
6     Actix        Rust           54.84   1712.13ms   3487.93ms    0.00
7     Rocket       Rust           52.72   1785.04ms   4632.42ms    0.00
8     Axum         Rust           51.90   1815.53ms   4180.09ms    0.00

--- Proxy 100KB Image ---
Rank  Framework    Language     RPS      Avg RT    P95 RT    Error%
----  -----------  ----------   -------  --------  --------  ------
1     Gin          Go           1819.00     37.82ms     63.46ms    0.00
2     Fiber        Go           1743.29     39.99ms     63.91ms    0.00
3     Hono         TypeScript    710.43    118.43ms    223.56ms    0.00
4     Fastify      TypeScript    680.28    124.27ms    232.00ms    0.00
5     Echo         Go            178.28    514.44ms   1717.30ms    7.00
6     Rocket       Rust           52.01   1818.53ms   4202.35ms    0.00
7     Actix        Rust           51.58   1824.83ms   3702.99ms    0.00
8     Axum         Rust           50.32   1876.86ms   4509.03ms    0.00

--- Overall Statistics ---
Best Local Performance: Fiber (7257.29 RPS for 20k)
Best Proxy Performance: Gin (2388.58 RPS for 20k)

=== Benchmark Complete ===
Total time: 88m 34s

Benchmark complete!
```

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

### AWS 環境（CDK で EC2 をプロビジョニングする場合）

- AWS CLI がインストールされ、設定済みであること
- AWS CDK がインストールされていること（`npm install -g aws-cdk`）
- EC2 キーペアが作成済みであること

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
sudo ./setup-amazon-linux.sh

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

## AWS CDK で EC2 環境を構築する場合

### CDK のセットアップ

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

CDK の出力から、サーバーとクライアントの IP アドレスを確認し、SSH で接続します：

```bash
# サーバーインスタンスに接続
ssh -i ~/.ssh/benchmark-key.pem ec2-user@<server-ip>

# リポジトリがすでにクローンされているので
cd ~/image-server-benchmark
sudo ./setup-amazon-linux.sh
./start-servers.sh

# クライアントインスタンスに接続（別ターミナル）
ssh -i ~/.ssh/benchmark-key.pem ec2-user@<client-ip>

cd ~/image-server-benchmark
echo "SERVER_IP=<server-private-ip>" >> .env
sudo ./setup-amazon-linux.sh
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

### npm install で dotenv が見つからない

各サーバーが`servers/common`モジュールに依存しているため、common モジュールのインストールが必要です：

```bash
cd ~/image-server-benchmark
cd servers/common && npm install
cd ../typescript/fastify && npm install
cd ../typescript/hono && npm install
```

または、セットアップスクリプトを再実行：

```bash
sudo ./setup-amazon-linux.sh
```

### Rust のビルドエラー（openssl-sys）

Amazon Linux の場合（setup-amazon-linux.sh で自動インストールされます）：

```bash
sudo dnf install -y openssl-devel pkg-config
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
