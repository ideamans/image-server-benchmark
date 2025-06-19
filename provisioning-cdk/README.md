# Image Server Benchmark - CDK Infrastructure

このディレクトリには、Image Server Benchmark のインフラストラクチャをプロビジョニングするための AWS CDK コードが含まれています。

## 前提条件

- AWS CLI が設定済みであること
- Node.js 18.x 以上がインストールされていること
- AWS CDK がインストールされていること（`npm install -g aws-cdk`）
- 有効な AWS アカウントとクレデンシャル

## セットアップ

1. 依存関係のインストール:

```bash
cd provisioning-cdk
npm install
```

2. プロジェクトルートの`.env`ファイルを設定:

```bash
cd ..
cp .env.example .env
# .envファイルを編集して必要な値を設定
```

3. CDK のブートストラップ（初回のみ）:

```bash
cd provisioning-cdk
npx cdk bootstrap
```

## デプロイ

### 設定の確認

```bash
npm run config:check
```

### スタックのデプロイ

```bash
# ビルドとデプロイ
npm run deploy

# または、キーペアを指定してデプロイ
npx cdk deploy --parameters KeyPairName=your-key-pair-name
```

### デプロイされるリソース

- **VPC**: パブリックサブネット 1 つを持つシンプルな VPC
- **セキュリティグループ**: サーバー用とクライアント用の 2 つ
- **EC2 インスタンス**:
  - サーバーインスタンス（ベンチマーク対象の Web サーバーを実行）
  - クライアントインスタンス（k6 ベンチマークツールを実行）
- **Elastic IP**: 各インスタンスに 1 つずつ
- **IAM ロール**: CloudWatch と Session Manager 用

## 使用方法

1. デプロイ完了後、CDK の出力から SSH コマンドを確認:

```bash
ServerSshCommand: ssh -i ~/.ssh/your-key.pem ec2-user@xxx.xxx.xxx.xxx
ClientSshCommand: ssh -i ~/.ssh/your-key.pem ec2-user@yyy.yyy.yyy.yyy
```

2. サーバーインスタンスに接続:

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<server-ip>
cd ~/image-server-benchmark
./scripts/setup-server.sh
./scripts/start-servers.sh
```

3. クライアントインスタンスに接続:

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<client-ip>
cd ~/image-server-benchmark
# サーバーインスタンスのプライベートIPを設定（CDK出力で確認）
echo "SERVER_IP=<server-private-ip>" >> .env
./scripts/setup-client.sh
./scripts/run-benchmark.sh
```

## クリーンアップ

リソースを削除してコストを節約:

```bash
npm run destroy
# または
npx cdk destroy
```

## トラブルシューティング

### キーペアが見つからない

```bash
# 新しいキーペアを作成
aws ec2 create-key-pair --key-name benchmark-key --query 'KeyMaterial' --output text > ~/.ssh/benchmark-key.pem
chmod 400 ~/.ssh/benchmark-key.pem
```

### デプロイが失敗する

```bash
# スタックの状態を確認
aws cloudformation describe-stacks --stack-name ImageServerBenchmarkStack

# 失敗したスタックを削除
aws cloudformation delete-stack --stack-name ImageServerBenchmarkStack
```

## カスタマイズ

### インスタンスタイプの変更

`.env`ファイルで設定:

```
SERVER_INSTANCE_TYPE=t4g.small
CLIENT_INSTANCE_TYPE=m6g.4xlarge
```

### リージョンの変更

```
AWS_REGION=ap-northeast-1
```

## セキュリティに関する注意

- セキュリティグループは必要最小限のポートのみを開放しています
- SSH 接続にはキーペアが必要です
- Session Manager も利用可能です（キーペアなしでアクセス可能）

## 自動シャットダウン機能

安全のため、EC2インスタンスは起動から3時間後に自動的にシャットダウンされます。

- デフォルト: 180分（3時間）後に自動シャットダウン
- `.env`で`AUTO_SHUTDOWN_MINUTES=0`を設定すると無効化できます
- インスタンスにSSH接続すると、自動シャットダウンの警告が表示されます
- 自動シャットダウンをキャンセルするには: `sudo systemctl stop auto-shutdown.timer`

## コスト見積もり

デフォルト設定での概算コスト（us-east-1）:

- m6g.medium (サーバー): ~$0.0084/時間
- m6g.4xlarge (クライアント): ~$0.308/時間
- 合計: ~$0.317/時間

**注意**: 使用後は必ずリソースを削除してください。
