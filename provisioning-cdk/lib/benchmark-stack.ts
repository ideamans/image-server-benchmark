import * as cdk from "aws-cdk-lib";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import { Construct } from "constructs";
import { BenchmarkNetwork } from "./constructs/benchmark-network";
import { BenchmarkInstance } from "./constructs/benchmark-instance";
import { ConfigReader, BenchmarkConfig } from "./config-reader";
import * as fs from "fs";
import * as path from "path";

export class ImageServerBenchmarkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // .env設定の読み込み
    const config = ConfigReader.loadConfig();

    try {
      ConfigReader.validateConfig(config);
    } catch (error) {
      console.warn("Configuration validation warning:", error);
    }

    // キーペアパラメータ（.envから取得、未設定時はパラメータで指定）
    const keyPairParam = new cdk.CfnParameter(this, "KeyPairName", {
      type: "AWS::EC2::KeyPair::KeyName",
      description: "Name of an existing EC2 KeyPair to enable SSH access",
      default: config.keyPairName || undefined,
    });

    const keyPairName = config.keyPairName || keyPairParam.valueAsString;

    // インスタンスタイプを.envから取得
    const serverInstanceType = new ec2.InstanceType(config.serverInstanceType);
    const clientInstanceType = new ec2.InstanceType(config.clientInstanceType);

    // ネットワーク構成
    const network = new BenchmarkNetwork(this, "Network", { config });

    // ユーザーデータスクリプトの読み込み
    const serverUserData = this.loadUserDataScript("server", config);
    const clientUserData = this.loadUserDataScript("client", config);

    // サーバーインスタンス
    const serverInstance = new BenchmarkInstance(this, "ServerInstance", {
      vpc: network.vpc,
      securityGroup: network.serverSecurityGroup,
      keyName: keyPairName,
      instanceType: serverInstanceType,
      userData: serverUserData,
      role: "server",
    });

    // サーバーインスタンスにタグを追加
    cdk.Tags.of(serverInstance).add("Name", "image-web-server-benchmark-server");

    // クライアントインスタンス
    const clientInstance = new BenchmarkInstance(this, "ClientInstance", {
      vpc: network.vpc,
      securityGroup: network.clientSecurityGroup,
      keyName: keyPairName,
      instanceType: clientInstanceType,
      userData: clientUserData,
      role: "client",
    });

    // クライアントインスタンスにタグを追加
    cdk.Tags.of(clientInstance).add("Name", "image-web-server-benchmark-client");

    // スタック出力
    new cdk.CfnOutput(this, "VPCId", {
      value: network.vpc.vpcId,
      description: "VPC ID",
    });

    new cdk.CfnOutput(this, "ServerSecurityGroupId", {
      value: network.serverSecurityGroup.securityGroupId,
      description: "Server Security Group ID",
    });

    new cdk.CfnOutput(this, "ClientSecurityGroupId", {
      value: network.clientSecurityGroup.securityGroupId,
      description: "Client Security Group ID",
    });

    // インスタンス情報の出力
    new cdk.CfnOutput(this, "ServerInfo", {
      value: `Server (image-web-server-benchmark-server): ${serverInstance.elasticIp.ref}`,
      description: "Server instance hostname and IP",
    });

    new cdk.CfnOutput(this, "ClientInfo", {
      value: `Client (image-web-server-benchmark-client): ${clientInstance.elasticIp.ref}`,
      description: "Client instance hostname and IP",
    });

    // Quick Start Instructions
    new cdk.CfnOutput(this, "QuickStartInstructions", {
      value: `
1. Connect to servers:
   Server: ssh -i ~/.ssh/${keyPairName}.pem ec2-user@${serverInstance.elasticIp.ref}
   Client: ssh -i ~/.ssh/${keyPairName}.pem ec2-user@${clientInstance.elasticIp.ref}

2. On the server instance:
   cd ~/image-server-benchmark
   sudo ./setup-amazon-linux.sh
   ./start-servers.sh

3. On the client instance:
   cd ~/image-server-benchmark
   echo "SERVER_IP=${serverInstance.instance.instancePrivateIp}" >> .env
   sudo ./setup-amazon-linux.sh
   ./run-benchmark.sh
      `.trim(),
      description: "Quick start instructions for running the benchmark",
    });

    // タグ付け（コスト管理用）
    cdk.Tags.of(this).add("Project", "image-server-benchmark");
    cdk.Tags.of(this).add("Environment", "benchmark");
    cdk.Tags.of(this).add("ManagedBy", "cdk");
  }

  private loadUserDataScript(
    role: "server" | "client",
    config: BenchmarkConfig
  ): string {
    // ユーザーデータスクリプトのテンプレート
    const template = `#!/bin/bash
set -e

# ログ出力の設定
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== User Data Script Started at $(date) ==="
echo "Running as: $(whoami)"
echo "Current directory: $(pwd)"

# ホスト名の設定
HOSTNAME="${role === 'server' ? 'image-web-server-benchmark-server' : 'image-web-server-benchmark-client'}"
echo "Setting hostname to: $HOSTNAME"
sudo hostnamectl set-hostname $HOSTNAME
echo "$HOSTNAME" | sudo tee /etc/hostname

# /etc/hostsファイルの更新
sudo sed -i "s/localhost.localdomain/$HOSTNAME localhost.localdomain/" /etc/hosts

# 環境変数の設定
export ORIGIN_URL_BASE="${config.originUrlBase}"
export SERVER_START_PORT="${config.serverStartPort}"
export SERVER_WORKER_THREADS="${config.serverWorkerThreads}"
export BENCHMARK_DURATION="${config.benchmarkDuration}"
export BENCHMARK_WARMUP_DURATION="${config.benchmarkWarmupDuration}"
export BENCHMARK_COOLDOWN_DURATION="${config.benchmarkCooldownDuration}"
export MAX_VUS="${config.maxVus}"
export ERROR_THRESHOLD="${config.errorThreshold}"
export RESPONSE_TIME_THRESHOLD="${config.responseTimeThreshold}"

# システムアップデート
sudo dnf update -y

# 基本ツールインストール
sudo dnf install -y git htop vim tmux tree jq

# Node.js 20.xのインストール
sudo dnf install -y nodejs20 nodejs20-npm || {
  # フォールバック: NodeSourceリポジトリを使用
  curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
  sudo dnf install -y nodejs
}

# Node.jsのシンボリックリンクを作成（必要な場合）
if [ -f /usr/bin/node20 ] && [ ! -f /usr/bin/node ]; then
  sudo ln -sf /usr/bin/node20 /usr/bin/node
  sudo ln -sf /usr/bin/npm20 /usr/bin/npm
fi

# リポジトリクローン
echo "Cloning repository..."
cd /home/ec2-user
sudo -u ec2-user git clone https://github.com/ideamans/image-server-benchmark.git || {
  echo "Git clone failed with exit code: $?"
  echo "Checking network connectivity..."
  curl -s https://github.com > /dev/null && echo "GitHub is reachable" || echo "Cannot reach GitHub"
  exit 1
}
if [ ! -d "image-server-benchmark" ]; then
  echo "Repository directory not found after clone"
  exit 1
fi
echo "Repository cloned successfully"
sudo chown -R ec2-user:ec2-user image-server-benchmark

# .envファイルの作成
cat << EOF > /home/ec2-user/image-server-benchmark/.env
ORIGIN_URL_BASE=${config.originUrlBase}
SERVER_START_PORT=${config.serverStartPort}
SERVER_WORKER_THREADS=${config.serverWorkerThreads}
BENCHMARK_DURATION=${config.benchmarkDuration}
BENCHMARK_WARMUP_DURATION=${config.benchmarkWarmupDuration}
BENCHMARK_COOLDOWN_DURATION=${config.benchmarkCooldownDuration}
MAX_VUS=${config.maxVus}
ERROR_THRESHOLD=${config.errorThreshold}
RESPONSE_TIME_THRESHOLD=${config.responseTimeThreshold}
EOF

chown ec2-user:ec2-user /home/ec2-user/image-server-benchmark/.env

# ロール固有の設定
${
  role === "server"
    ? this.getServerSpecificSetup()
    : this.getClientSpecificSetup()
}

# セットアップ手順を作成
cat << 'EOF' > /home/ec2-user/SETUP_INSTRUCTIONS.txt
Image Server Benchmark - ${
      role.charAt(0).toUpperCase() + role.slice(1)
    } Instance

リポジトリがクローンされ、.envファイルが設定されました。

${role === "server" ? "サーバーのセットアップ:" : "クライアントのセットアップ:"}
cd ~/image-server-benchmark
${
  role === "server"
    ? "sudo ./setup-amazon-linux.sh  # 環境構築（初回のみ、5-10分程度）\n./start-servers.sh            # サーバー起動"
    : 'echo "SERVER_IP=<サーバーのプライベートIP>" >> .env\nsudo ./setup-amazon-linux.sh  # 環境構築（初回のみ、5-10分程度）\n./run-benchmark.sh            # ベンチマーク実行'
}

詳細はREADME.mdを参照してください。
EOF

chown ec2-user:ec2-user /home/ec2-user/SETUP_INSTRUCTIONS.txt

# MOTDの設定
sudo sh -c 'cat /home/ec2-user/SETUP_INSTRUCTIONS.txt > /etc/motd'

# 自動シャットダウンの設定
AUTO_SHUTDOWN_MINUTES="${config.autoShutdownMinutes}"
if [ "$AUTO_SHUTDOWN_MINUTES" -gt 0 ]; then
  echo "Setting up auto-shutdown after $AUTO_SHUTDOWN_MINUTES minutes..."
  
  # シャットダウンスクリプトの作成
  cat << 'SHUTDOWN_SCRIPT' > /usr/local/bin/auto-shutdown.sh
#!/bin/bash
logger -t auto-shutdown "Auto-shutdown initiated after $AUTO_SHUTDOWN_MINUTES minutes"
wall "This instance will shutdown in 5 minutes due to auto-shutdown policy!"
sleep 300
shutdown -h now
SHUTDOWN_SCRIPT
  
  chmod +x /usr/local/bin/auto-shutdown.sh
  
  # systemdタイマーの作成
  cat << TIMER_EOF > /etc/systemd/system/auto-shutdown.timer
[Unit]
Description=Auto shutdown timer

[Timer]
OnBootSec=$AUTO_SHUTDOWN_MINUTES\min
Unit=auto-shutdown.service

[Install]
WantedBy=timers.target
TIMER_EOF

  cat << 'SERVICE_EOF' > /etc/systemd/system/auto-shutdown.service
[Unit]
Description=Auto shutdown service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-shutdown.sh
SERVICE_EOF

  # タイマーの有効化
  systemctl daemon-reload
  systemctl enable auto-shutdown.timer
  systemctl start auto-shutdown.timer
  
  echo "Auto-shutdown timer enabled. Instance will shutdown after $AUTO_SHUTDOWN_MINUTES minutes."
  
  # MOTDに自動シャットダウンの警告を追加
  echo "" >> /etc/motd
  echo "⚠️  WARNING: This instance will auto-shutdown after $AUTO_SHUTDOWN_MINUTES minutes from boot!" >> /etc/motd
  echo "To cancel: sudo systemctl stop auto-shutdown.timer" >> /etc/motd
fi

echo "User data script completed successfully"
`;

    return template;
  }

  private getServerSpecificSetup(): string {
    return `
# サーバー固有の設定
# 必要なランタイムのプリインストール（オプション）
# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u ec2-user sh -s -- -y
source /home/ec2-user/.cargo/env

# Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/ec2-user/.bashrc
rm go1.21.5.linux-amd64.tar.gz

# Bun
curl -fsSL https://bun.sh/install | sudo -u ec2-user bash

# ポート設定の確認
echo "Server will use ports \${SERVER_START_PORT} to \$((\${SERVER_START_PORT} + 8))"
`;
  }

  private getClientSpecificSetup(): string {
    return `
# クライアント固有の設定
# k6のインストール
sudo dnf install -y https://dl.k6.io/rpm/repo.rpm
sudo dnf install -y k6

echo "Client instance ready for benchmarking"
`;
  }
}
