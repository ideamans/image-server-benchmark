# Image Server Benchmark - CDK Infrastructure

このディレクトリには、Image Server BenchmarkのインフラストラクチャをプロビジョニングするためのAWS CDKコードが含まれています。

## 前提条件

- AWS CLI が設定済みであること
- Node.js 18.x 以上がインストールされていること
- AWS CDK がインストールされていること（`npm install -g aws-cdk`）
- 有効なAWSアカウントとクレデンシャル

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

3. CDKのブートストラップ（初回のみ）:
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

- **VPC**: パブリックサブネット1つを持つシンプルなVPC
- **セキュリティグループ**: サーバー用とクライアント用の2つ
- **EC2インスタンス**: 
  - サーバーインスタンス（ベンチマーク対象のWebサーバーを実行）
  - クライアントインスタンス（k6ベンチマークツールを実行）
- **Elastic IP**: 各インスタンスに1つずつ
- **IAMロール**: CloudWatchとSession Manager用

## 使用方法

1. デプロイ完了後、CDKの出力からSSHコマンドを確認:
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
echo "SERVER_IP=<server-ip>" >> .env
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
SERVER_INSTANCE_TYPE=c5.4xlarge
CLIENT_INSTANCE_TYPE=m5.2xlarge
```

### リージョンの変更
```
AWS_REGION=ap-northeast-1
```

## セキュリティに関する注意

- セキュリティグループは必要最小限のポートのみを開放しています
- SSH接続にはキーペアが必要です
- Session Managerも利用可能です（キーペアなしでアクセス可能）

## コスト見積もり

デフォルト設定での概算コスト（us-east-1）:
- c5.2xlarge (サーバー): ~$0.34/時間
- m5.xlarge (クライアント): ~$0.19/時間
- 合計: ~$0.53/時間

**注意**: 使用後は必ずリソースを削除してください。