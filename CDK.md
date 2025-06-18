# Image Server Benchmark - CDK Stack 設計仕様

## 1. provisioning-cdk ディレクトリ構造

```
provisioning-cdk/
├── bin/
│   └── provisioning-cdk.ts          # CDKアプリケーションのエントリーポイント
├── lib/
│   ├── benchmark-stack.ts           # メインスタック定義
│   ├── config-reader.ts             # .env設定読み込みユーティリティ
│   ├── constructs/
│   │   ├── benchmark-instance.ts    # EC2インスタンス構成
│   │   └── benchmark-network.ts     # ネットワーク構成
│   └── user-data/
│       ├── server-init.sh           # サーバー用初期化スクリプト
│       └── client-init.sh           # クライアント用初期化スクリプト
├── cdk.json                         # CDK設定
├── package.json                     # 依存関係定義
├── tsconfig.json                    # TypeScript設定
└── README.md                        # CDK使用方法
```

## 2. 環境設定読み込み

### 2.1 config-reader.ts

```typescript
// .envファイルをプロジェクトルートから読み込む
export interface BenchmarkConfig {
  // AWS設定
  keyPairName: string;
  awsRegion: string;

  // インスタンス設定
  serverInstanceType: string;
  clientInstanceType: string;

  // アプリケーション設定
  originUrlBase: string;
  serverStartPort: number;

  // ベンチマーク設定
  benchmarkDuration: string;
  maxVus: number;
}

export class ConfigReader {
  static loadConfig(): BenchmarkConfig {
    // ../.envファイルを読み込み
    // デフォルト値を設定
    // 環境変数からのオーバーライド対応
  }
}
```

### 2.2 ネットワーク構成の更新

```typescript
// benchmark-network.ts - ポート範囲を.envから取得
class BenchmarkNetwork extends Construct {
  constructor(scope: Construct, id: string, config: BenchmarkConfig) {
    // セキュリティグループのポート開放を動的に設定
    const startPort = config.serverStartPort;
    const endPort = startPort + 8; // 9サーバー分

    this.serverSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcpRange(startPort, endPort),
      `Allow benchmark server ports ${startPort}-${endPort}`
    );
  }
}
```

## 3. CDK Stack 主要コンポーネント

### 2.1 ネットワーク構成

```typescript
// benchmark-network.ts の概要
class BenchmarkNetwork extends Construct {
  public readonly vpc: ec2.Vpc;
  public readonly serverSecurityGroup: ec2.SecurityGroup;
  public readonly clientSecurityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, id: string) {
    // VPC作成（パブリックサブネットのみ）
    this.vpc = new ec2.Vpc(this, "BenchmarkVPC", {
      maxAzs: 1,
      natGateways: 0,
      subnetConfiguration: [
        {
          name: "Public",
          subnetType: ec2.SubnetType.PUBLIC,
        },
      ],
    });

    // サーバー用セキュリティグループ
    this.serverSecurityGroup = new ec2.SecurityGroup(this, "ServerSG", {
      vpc: this.vpc,
      description: "Security group for benchmark server",
    });
    // ポート3001-3009を開放
    for (let port = 3001; port <= 3009; port++) {
      this.serverSecurityGroup.addIngressRule(
        ec2.Peer.anyIpv4(),
        ec2.Port.tcp(port),
        `Allow inbound traffic on port ${port}`
      );
    }

    // クライアント用セキュリティグループ
    this.clientSecurityGroup = new ec2.SecurityGroup(this, "ClientSG", {
      vpc: this.vpc,
      description: "Security group for benchmark client",
    });
  }
}
```

### 2.2 EC2 インスタンス構成

```typescript
// benchmark-instance.ts の概要
interface BenchmarkInstanceProps {
  vpc: ec2.Vpc;
  securityGroup: ec2.SecurityGroup;
  keyName: string;
  instanceType: ec2.InstanceType;
  userData: string;
  role: "server" | "client";
}

class BenchmarkInstance extends Construct {
  public readonly instance: ec2.Instance;
  public readonly elasticIp: ec2.CfnEIP;

  constructor(scope: Construct, id: string, props: BenchmarkInstanceProps) {
    // IAMロール（CloudWatch Logsへのアクセス権限）
    const role = new iam.Role(this, "InstanceRole", {
      assumedBy: new iam.ServicePrincipal("ec2.amazonaws.com"),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName(
          "CloudWatchAgentServerPolicy"
        ),
      ],
    });

    // EC2インスタンス
    this.instance = new ec2.Instance(this, "Instance", {
      vpc: props.vpc,
      instanceType: props.instanceType,
      machineImage: new ec2.AmazonLinuxImage({
        generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2023,
      }),
      keyName: props.keyName,
      securityGroup: props.securityGroup,
      role: role,
      userData: ec2.UserData.custom(props.userData),
      blockDevices: [
        {
          deviceName: "/dev/xvda",
          volume: ec2.BlockDeviceVolume.ebs(30, {
            volumeType: ec2.EbsDeviceVolumeType.GP3,
          }),
        },
      ],
    });

    // Elastic IP
    this.elasticIp = new ec2.CfnEIP(this, "EIP", {
      instanceId: this.instance.instanceId,
    });
  }
}
```

### 3.3 メインスタックの更新

```typescript
// benchmark-stack.ts - .env設定を活用
export class ImageServerBenchmarkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // .env設定の読み込み
    const config = ConfigReader.loadConfig();

    // キーペアパラメータ（.envから取得、未設定時はパラメータで指定）
    const keyPairName =
      config.keyPairName ||
      new cdk.CfnParameter(this, "KeyPairName", {
        type: "String",
        description: "Name of an existing EC2 KeyPair",
      }).valueAsString;

    // インスタンスタイプを.envから取得
    const serverInstanceType = new ec2.InstanceType(config.serverInstanceType);
    const clientInstanceType = new ec2.InstanceType(config.clientInstanceType);

    // 環境変数をUserDataに渡す
    const envVars = {
      ORIGIN_URL_BASE: config.originUrlBase,
      SERVER_START_PORT: config.serverStartPort.toString(),
      // その他必要な環境変数
    };

    // タグ付け（コスト管理用）
    cdk.Tags.of(this).add("Project", "image-server-benchmark");
    cdk.Tags.of(this).add("Environment", "benchmark");
  }
}
```

## 4. User Data スクリプトの更新

### 4.1 サーバー用初期化スクリプト (server-init.sh)

```bash
#!/bin/bash
set -e

# 環境変数の設定（CDKから渡される）
export ORIGIN_URL_BASE="${ORIGIN_URL_BASE}"
export SERVER_START_PORT="${SERVER_START_PORT}"

# システムアップデート
sudo yum update -y

# 基本ツールインストール
sudo yum install -y git htop vim tmux

# リポジトリクローン
cd /home/ec2-user
git clone https://github.com/idaemans/image-server-benchmark.git
chown -R ec2-user:ec2-user image-server-benchmark

# .envファイルの作成
cat << EOF > /home/ec2-user/image-server-benchmark/.env
ORIGIN_URL_BASE=${ORIGIN_URL_BASE}
SERVER_START_PORT=${SERVER_START_PORT}
SERVER_WORKER_THREADS=0
EOF

chown ec2-user:ec2-user /home/ec2-user/image-server-benchmark/.env

# セットアップ手順
cat << EOF > /home/ec2-user/SETUP_INSTRUCTIONS.txt
Image Server Benchmark - Server Instance

リポジトリがクローンされ、.envファイルが設定されました。
セットアップを続行するには:

cd ~/image-server-benchmark
./scripts/setup-server.sh
./scripts/start-servers.sh

詳細はREADME.mdを参照してください。
EOF

chown ec2-user:ec2-user /home/ec2-user/SETUP_INSTRUCTIONS.txt
```

### 4.2 クライアント用初期化スクリプト (client-init.sh)

```bash
#!/bin/bash
set -e

# 環境変数の設定（CDKから渡される）
export BENCHMARK_DURATION="${BENCHMARK_DURATION}"
export MAX_VUS="${MAX_VUS}"

# システムアップデート
sudo yum update -y

# 基本ツールインストール
sudo yum install -y git htop vim tmux

# リポジトリクローン
cd /home/ec2-user
git clone https://github.com/idaemans/image-server-benchmark.git
chown -R ec2-user:ec2-user image-server-benchmark

# .envファイルの作成（ベンチマーク設定）
cat << EOF > /home/ec2-user/image-server-benchmark/.env
BENCHMARK_DURATION=${BENCHMARK_DURATION}
BENCHMARK_WARMUP_DURATION=10s
BENCHMARK_COOLDOWN_DURATION=10s
MAX_VUS=${MAX_VUS}
ERROR_THRESHOLD=0.01
RESPONSE_TIME_THRESHOLD=1000
EOF

chown ec2-user:ec2-user /home/ec2-user/image-server-benchmark/.env

# セットアップ手順（サーバーIP記入を促す）
cat << EOF > /home/ec2-user/SETUP_INSTRUCTIONS.txt
Image Server Benchmark - Client Instance

リポジトリがクローンされ、ベンチマーク設定が完了しました。

実行前に.envファイルにサーバーIPを追加してください:
echo "SERVER_IP=<サーバーのIP>" >> ~/image-server-benchmark/.env

その後、以下を実行:
cd ~/image-server-benchmark
./scripts/setup-client.sh
./scripts/run-benchmark.sh

詳細はREADME.mdを参照してください。
EOF

chown ec2-user:ec2-user /home/ec2-user/SETUP_INSTRUCTIONS.txt
```

## 5. package.json 設定

```json
{
  "name": "provisioning-cdk",
  "version": "1.0.0",
  "description": "CDK stack for Image Server Benchmark infrastructure",
  "main": "bin/provisioning-cdk.js",
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "cdk": "cdk",
    "deploy": "npm run build && cdk deploy",
    "destroy": "cdk destroy",
    "synth": "cdk synth",
    "config:check": "node -e \"console.log(require('./lib/config-reader').ConfigReader.loadConfig())\""
  },
  "devDependencies": {
    "@types/node": "20.x",
    "aws-cdk": "2.x",
    "ts-node": "^10.9.1",
    "typescript": "~5.2.0"
  },
  "dependencies": {
    "aws-cdk-lib": "2.x",
    "constructs": "^10.0.0",
    "dotenv": "^16.3.1"
  }
}
```

## 6. CDK デプロイ手順（.env 対応版）

```bash
# 1. .envファイルの準備
cd image-server-benchmark
cp .env.example .env
# .envファイルを編集

# 2. AWS認証情報の設定確認
aws configure list

# 3. CDKのブートストラップ（初回のみ）
cd provisioning-cdk
npm install
npx cdk bootstrap

# 4. 設定の確認
npm run config:check

# 5. スタックの確認
npx cdk synth

# 6. デプロイ実行
npx cdk deploy
# または、.envにキーペアが未設定の場合
npx cdk deploy --parameters KeyPairName=your-key-pair

# 7. 出力の確認
# CDKの出力からIPアドレスを確認し、必要に応じて.envを更新

# 8. 実験終了後のクリーンアップ
npx cdk destroy
```

## 7. .env.example ファイル

```bash
# Image Server Benchmark Configuration

# === AWS Configuration ===
# EC2インスタンスで使用するキーペア名
KEY_PAIR_NAME=

# AWSリージョン
AWS_REGION=us-east-1

# === Instance Configuration ===
# サーバーインスタンスタイプ（高いCPU性能推奨）
SERVER_INSTANCE_TYPE=c5.2xlarge

# クライアントインスタンスタイプ
CLIENT_INSTANCE_TYPE=m5.xlarge

# === Application Configuration ===
# プロキシ動作時のオリジンURL（末尾スラッシュ必須）
# この中の20k.jpg, 50k.jpg, 100k.jpgをプロキシします
ORIGIN_URL_BASE=https://example-bucket.s3.amazonaws.com/images/

# サーバーの開始ポート番号（3001-3009を使用）
SERVER_START_PORT=3001

# ワーカースレッド数（0=自動：CPUコア数）
SERVER_WORKER_THREADS=0

# === Benchmark Configuration ===
# ベンチマーク対象サーバーのIP（クライアント実行時に使用）
SERVER_IP=

# 各テストの実行時間
BENCHMARK_DURATION=60s

# ウォームアップ時間
BENCHMARK_WARMUP_DURATION=10s

# クールダウン時間（テスト間の待機時間）
BENCHMARK_COOLDOWN_DURATION=10s

# 最大仮想ユーザー数
MAX_VUS=200

# エラー率閾値（1% = 0.01）
ERROR_THRESHOLD=0.01

# レスポンスタイム閾値（ミリ秒）
RESPONSE_TIME_THRESHOLD=1000
```

## 8. セキュリティとコスト管理
