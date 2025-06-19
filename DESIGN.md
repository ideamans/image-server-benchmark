# 画像配信 Web サーバー ベンチマーク実験設計書

## プロジェクト情報

- **リポジトリ**: https://github.com/idaemans/image-server-benchmark
- **ライセンス**: MIT
- **目的**: 異なる言語・フレームワークによる画像配信サーバーの性能比較

## 1. 実験概要

### 目的

TypeScript、Go、Rust の 3 言語で実装された高速 Web サーバーフレームワークを使用し、画像配信のスループット性能を比較評価する。

### 測定対象

- **言語**: TypeScript、Go、Rust（各 3 フレームワーク）
- **配信パターン**:
  - ローカルディスク画像（20KB、50KB、100KB）
  - プロキシ画像（20KB、50KB、100KB）
- **測定項目**: 限界スループット（req/sec）

## 2. システム構成

### 2.1 環境設定（.env）

プロジェクトルートの`.env`ファイルで全体設定を管理：

```bash
# プロキシ動作のオリジンURL
ORIGIN_URL_BASE=http://example-bucket.s3.amazonaws.com/images/

# ベンチマーク対象サーバーのIP（クライアント実行時に使用）
SERVER_IP=10.0.0.1

# AWS設定
KEY_PAIR_NAME=my-benchmark-key
AWS_REGION=us-east-1

# インスタンスタイプ
SERVER_INSTANCE_TYPE=t3.small
CLIENT_INSTANCE_TYPE=t3.small

# ベンチマーク設定
BENCHMARK_DURATION=60s
BENCHMARK_WARMUP_DURATION=10s
BENCHMARK_COOLDOWN_DURATION=10s
MAX_VUS=200
ERROR_THRESHOLD=0.01
RESPONSE_TIME_THRESHOLD=1000

# サーバー設定
SERVER_START_PORT=3001
SERVER_WORKER_THREADS=0  # 0=auto (CPU cores)
```

### 2.2 サーバー構成（EC2 インスタンス A）

- 9 個の Web サーバーを異なるポートで起動
- ポート割り当て:
  - TypeScript: 3001-3003
  - Go: 3004-3006
  - Rust: 3007-3009

### 2.3 クライアント構成（EC2 インスタンス B）

- k6 による負荷テストクライアント
- 各サーバーの 6 エンドポイントを順次テスト

## 3. Web サーバー実装仕様

### 3.1 TypeScript フレームワーク選定

1. **Fastify** - 高速性を重視した Node.js フレームワーク
2. **Hono** - エッジコンピューティング対応の超軽量フレームワーク
3. **Bun + Elysia** - Bun ランタイム専用の高速フレームワーク

### 3.2 Go フレームワーク選定

1. **Fiber** - Express.js ライクな高速フレームワーク
2. **Gin** - 軽量で高速な HTTP フレームワーク
3. **Echo** - 高性能でミニマリスティックなフレームワーク

### 3.3 Rust フレームワーク選定

1. **Actix-web** - アクターモデルベースの高速フレームワーク
2. **Axum** - Tokio ベースのモダンなフレームワーク
3. **Rocket** - 開発効率と性能を両立したフレームワーク

### 3.4 エンドポイント設計

各サーバーは以下の 6 つのエンドポイントを実装:

- `GET /local/20k` - 20KB のローカル画像
- `GET /local/50k` - 50KB のローカル画像
- `GET /local/100k` - 100KB のローカル画像
- `GET /proxy/20k` - 20KB の外部画像をプロキシ（ORIGIN_URL_BASE + 20k.jpg）
- `GET /proxy/50k` - 50KB の外部画像をプロキシ（ORIGIN_URL_BASE + 50k.jpg）
- `GET /proxy/100k` - 100KB の外部画像をプロキシ（ORIGIN_URL_BASE + 100k.jpg）

### 3.5 サーバー共通設定

- **ワーカースレッド数**: SERVER_WORKER_THREADS（0 の場合は CPU コア数）
- **プロキシ元 URL**: ORIGIN_URL_BASE 環境変数から取得
- **ポート番号**: SERVER_START_PORT + オフセット値で自動計算

## 4. ディレクトリ構成

```
image-server-benchmark/
├── .env.example                      # 環境設定テンプレート
├── .env                             # 実際の環境設定（.gitignore対象）
├── .gitignore
├── provisioning-cdk/
│   ├── bin/
│   │   └── provisioning-cdk.ts
│   ├── lib/
│   │   ├── benchmark-stack.ts
│   │   ├── config-reader.ts      # .env読み込みユーティリティ
│   │   └── constructs/
│   │       ├── benchmark-instance.ts
│   │       └── benchmark-network.ts
│   ├── cdk.json
│   ├── package.json
│   ├── tsconfig.json
│   └── README.md
├── images/
│   ├── generate-images.sh          # テスト画像生成スクリプト
│   ├── 20k.jpg
│   ├── 50k.jpg
│   └── 100k.jpg
├── servers/
│   ├── common/
│   │   └── config-loader.js       # .env設定読み込み共通モジュール
│   ├── typescript/
│   │   ├── fastify/
│   │   ├── hono/
│   │   └── elysia/
│   ├── go/
│   │   ├── fiber/
│   │   ├── gin/
│   │   └── echo/
│   └── rust/
│       ├── actix/
│       ├── axum/
│       └── rocket/
├── k6/
│   ├── benchmark.js
│   └── config.js                  # .env設定読み込み
├── scripts/
│   ├── setup-server.sh
│   ├── start-servers.sh
│   ├── setup-client.sh
│   ├── run-benchmark.sh
│   └── utils/
│       └── load-env.sh           # シェルスクリプト用.env読み込み
├── results/
│   └── benchmark-results.tsv
├── LICENSE
└── README.md
```

## 5. k6 ベンチマークシナリオ

### 5.1 負荷パターン

- **ウォームアップ**: 10 秒間、10 VUs
- **メイン測定**: 60 秒間、VUs を段階的に増加
- **クールダウン**: 10 秒間（次のテストまでの待機）

### 5.2 測定手順

1. 各サーバーの各エンドポイントに対して順次実行
2. 限界スループット到達の判定基準:
   - エラー率が 1%を超える
   - レスポンスタイムの 95 パーセンタイルが 1 秒を超える
3. 測定結果を TSV 形式で保存

## 6. セットアップスクリプト仕様

### 6.1 setup-server.sh

- Node.js、Bun、Go、Rust の実行環境インストール
- 各言語の依存関係インストール
- 全サーバーのビルド実行
- テスト用画像の生成（ImageMagick 使用）

### 6.2 start-servers.sh

- 9 個のサーバーをバックグラウンドで起動
- プロセス管理（systemd または supervisor 使用）
- ヘルスチェック機能

### 6.3 setup-client.sh

- k6 のインストール
- 必要な依存関係のインストール

### 6.4 run-benchmark.sh

- サーバー IP アドレスの設定（.env の SERVER_IP 使用、未設定時は対話式入力）
- .env からベンチマーク設定を読み込み
- k6 スクリプトの実行
- 結果の TSV 変換と保存

## 7. 環境変数の利用箇所

### 7.1 CDK での利用

- `KEY_PAIR_NAME`: EC2 インスタンスのキーペア
- `AWS_REGION`: デプロイ先リージョン
- `SERVER_INSTANCE_TYPE`: サーバーインスタンスタイプ
- `CLIENT_INSTANCE_TYPE`: クライアントインスタンスタイプ

### 7.2 サーバー実装での利用

- `ORIGIN_URL_BASE`: プロキシ先のベース URL
- `SERVER_START_PORT`: サーバーの開始ポート番号
- `SERVER_WORKER_THREADS`: ワーカースレッド数

### 7.3 ベンチマークでの利用

- `SERVER_IP`: テスト対象サーバーの IP
- `BENCHMARK_DURATION`: 各テストの実行時間
- `BENCHMARK_WARMUP_DURATION`: ウォームアップ時間
- `BENCHMARK_COOLDOWN_DURATION`: クールダウン時間
- `MAX_VUS`: 最大仮想ユーザー数
- `ERROR_THRESHOLD`: エラー率閾値
- `RESPONSE_TIME_THRESHOLD`: レスポンスタイム閾値

## 7. 結果レポート形式（TSV）

```
Framework	Language	Image_Size	Type	Max_RPS	Avg_Response_Time_ms	P95_Response_Time_ms	Error_Rate
Fastify	TypeScript	20k	local	15234	65.2	89.3	0.02
Fastify	TypeScript	20k	proxy	8932	111.8	156.7	0.05
...
```

## 8. EC2 インスタンス推奨スペック

### サーバー側（インスタンス A）

- **インスタンスタイプ**: m7a.medium（ARM アーキテクチャ、開発・テスト用）
- **vCPU**: 2
- **メモリ**: 1GB
- **ネットワーク**: 最大 5Gbps

### クライアント側（インスタンス B）

- **インスタンスタイプ**: m7i.4xlarge（ARM アーキテクチャ、高性能ベンチマーク用）
- **vCPU**: 8
- **メモリ**: 32GB
- **ネットワーク**: 最大 10Gbps

### 共通設定

- **OS**: Ubuntu 22.04 LTS
- **セキュリティグループ**: ポート 3001-3009 を開放（サーバー側）
- **配置**: 同一アベイラビリティゾーン推奨

## 9. CDK による EC2 プロビジョニング

### 9.1 CDK スタック構成

- **スタック名**: ImageServerBenchmarkStack
- **リソース**:
  - VPC（新規作成）
  - セキュリティグループ（サーバー用・クライアント用）
  - EC2 インスタンス × 2（サーバー・クライアント）
  - Elastic IP × 2

### 9.2 CDK デプロイパラメータ

```bash
# デプロイ時に指定
cdk deploy --parameters KeyPairName=your-key-pair-name
```

### 9.3 EC2 ユーザーデータスクリプト

両インスタンスで以下を実行:

1. 必要なツールのインストール（git, htop, etc.）
2. リポジトリのクローン
3. 初期セットアップの準備

### 9.4 CDK 出力

- サーバーインスタンスのパブリック IP
- クライアントインスタンスのパブリック IP
- SSH 接続コマンド例

## 10. 実験手順

1. **EC2 インスタンス準備**

   - 2 台の EC2 インスタンスを起動
   - セキュリティグループ設定
   - SSH 接続確認

2. **コードベースのデプロイ**

   ```bash
   git clone https://github.com/yourrepo/image-server-benchmark.git
   cd image-server-benchmark
   ```

3. **サーバー側セットアップ（インスタンス A）**

   ```bash
   ./scripts/setup-server.sh
   ./scripts/start-servers.sh
   ```

4. **クライアント側セットアップ（インスタンス B）**

   ```bash
   ./scripts/setup-client.sh
   ./scripts/run-benchmark.sh
   ```

5. **結果確認**
   - `results/benchmark-results.tsv`を確認
   - 必要に応じて可視化ツールで分析

## 10. 実験手順

### 10.1 インフラストラクチャのプロビジョニング

```bash
# CDKのセットアップ
cd provisioning-cdk
npm install
npm run build

# キーペアが未作成の場合は作成
aws ec2 create-key-pair --key-name benchmark-key --query 'KeyMaterial' --output text > benchmark-key.pem
chmod 400 benchmark-key.pem

# スタックのデプロイ
cdk deploy --parameters KeyPairName=benchmark-key
```

### 10.2 インスタンスへの接続

```bash
# CDK出力から取得したIPアドレスを使用
ssh -i benchmark-key.pem ec2-user@<server-instance-ip>
ssh -i benchmark-key.pem ec2-user@<client-instance-ip>
```

### 10.3 サーバー側セットアップ（インスタンス A）

```bash
cd ~/image-server-benchmark
./scripts/setup-server.sh
./scripts/start-servers.sh
```

### 10.4 クライアント側セットアップ（インスタンス B）

```bash
cd ~/image-server-benchmark
./scripts/setup-client.sh
./scripts/run-benchmark.sh
# サーバーIPアドレスを入力（または.server-ipファイルに記載）
```

### 10.5 結果確認

- `results/benchmark-results.tsv`を確認
- 必要に応じて可視化ツールで分析

### 10.6 リソースのクリーンアップ

```bash
# CDKスタックの削除
cd provisioning-cdk
cdk destroy
```

## 11. 注意事項

- プロキシテスト用の外部画像サーバーは事前に準備が必要
- ネットワーク帯域がボトルネックにならないよう注意
- OS、カーネルパラメータのチューニングを検討
- 複数回実行して結果の再現性を確認
