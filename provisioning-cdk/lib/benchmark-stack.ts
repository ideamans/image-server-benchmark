import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';
import { BenchmarkNetwork } from './constructs/benchmark-network';
import { BenchmarkInstance } from './constructs/benchmark-instance';
import { ConfigReader, BenchmarkConfig } from './config-reader';
import * as fs from 'fs';
import * as path from 'path';

export class ImageServerBenchmarkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // .env設定の読み込み
    const config = ConfigReader.loadConfig();
    
    try {
      ConfigReader.validateConfig(config);
    } catch (error) {
      console.warn('Configuration validation warning:', error);
    }

    // キーペアパラメータ（.envから取得、未設定時はパラメータで指定）
    const keyPairParam = new cdk.CfnParameter(this, 'KeyPairName', {
      type: 'AWS::EC2::KeyPair::KeyName',
      description: 'Name of an existing EC2 KeyPair to enable SSH access',
      default: config.keyPairName || undefined,
    });

    const keyPairName = config.keyPairName || keyPairParam.valueAsString;

    // インスタンスタイプを.envから取得
    const serverInstanceType = new ec2.InstanceType(config.serverInstanceType);
    const clientInstanceType = new ec2.InstanceType(config.clientInstanceType);

    // ネットワーク構成
    const network = new BenchmarkNetwork(this, 'Network', { config });

    // ユーザーデータスクリプトの読み込み
    const serverUserData = this.loadUserDataScript('server', config);
    const clientUserData = this.loadUserDataScript('client', config);

    // サーバーインスタンス
    const serverInstance = new BenchmarkInstance(this, 'ServerInstance', {
      vpc: network.vpc,
      securityGroup: network.serverSecurityGroup,
      keyName: keyPairName,
      instanceType: serverInstanceType,
      userData: serverUserData,
      role: 'server',
    });

    // クライアントインスタンス
    const clientInstance = new BenchmarkInstance(this, 'ClientInstance', {
      vpc: network.vpc,
      securityGroup: network.clientSecurityGroup,
      keyName: keyPairName,
      instanceType: clientInstanceType,
      userData: clientUserData,
      role: 'client',
    });

    // スタック出力
    new cdk.CfnOutput(this, 'VPCId', {
      value: network.vpc.vpcId,
      description: 'VPC ID',
    });

    new cdk.CfnOutput(this, 'ServerSecurityGroupId', {
      value: network.serverSecurityGroup.securityGroupId,
      description: 'Server Security Group ID',
    });

    new cdk.CfnOutput(this, 'ClientSecurityGroupId', {
      value: network.clientSecurityGroup.securityGroupId,
      description: 'Client Security Group ID',
    });

    // Quick Start Instructions
    new cdk.CfnOutput(this, 'QuickStartInstructions', {
      value: `
1. Connect to servers:
   Server: ssh -i ~/.ssh/${keyPairName}.pem ec2-user@${serverInstance.elasticIp.ref}
   Client: ssh -i ~/.ssh/${keyPairName}.pem ec2-user@${clientInstance.elasticIp.ref}

2. On the server instance:
   cd ~/image-server-benchmark
   ./scripts/setup-server.sh
   ./scripts/start-servers.sh

3. On the client instance:
   cd ~/image-server-benchmark
   echo "SERVER_IP=${serverInstance.elasticIp.ref}" >> .env
   ./scripts/setup-client.sh
   ./scripts/run-benchmark.sh
      `.trim(),
      description: 'Quick start instructions for running the benchmark',
    });

    // タグ付け（コスト管理用）
    cdk.Tags.of(this).add('Project', 'image-server-benchmark');
    cdk.Tags.of(this).add('Environment', 'benchmark');
    cdk.Tags.of(this).add('ManagedBy', 'cdk');
  }

  private loadUserDataScript(role: 'server' | 'client', config: BenchmarkConfig): string {
    // ユーザーデータスクリプトのテンプレート
    const template = `#!/bin/bash
set -e

# ログ出力の設定
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

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
sudo yum update -y

# 基本ツールインストール
sudo yum install -y git htop vim tmux tree jq

# Node.js 20.xのインストール
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# リポジトリクローン
cd /home/ec2-user
sudo -u ec2-user git clone https://github.com/idaemans/image-server-benchmark.git || true
sudo chown -R ec2-user:ec2-user image-server-benchmark

# .envファイルの作成
cat << 'EOF' > /home/ec2-user/image-server-benchmark/.env
ORIGIN_URL=${config.originUrlBase}
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
${role === 'server' ? this.getServerSpecificSetup() : this.getClientSpecificSetup()}

# セットアップ手順を作成
cat << 'EOF' > /home/ec2-user/SETUP_INSTRUCTIONS.txt
Image Server Benchmark - ${role.charAt(0).toUpperCase() + role.slice(1)} Instance

リポジトリがクローンされ、.envファイルが設定されました。

${role === 'server' ? 'サーバーのセットアップ:' : 'クライアントのセットアップ:'}
cd ~/image-server-benchmark
${role === 'server' ? './scripts/setup-server.sh\n./scripts/start-servers.sh' : 'echo "SERVER_IP=<サーバーのIP>" >> .env\n./scripts/setup-client.sh\n./scripts/run-benchmark.sh'}

詳細はREADME.mdを参照してください。
EOF

chown ec2-user:ec2-user /home/ec2-user/SETUP_INSTRUCTIONS.txt

# MOTDの設定
sudo sh -c 'cat /home/ec2-user/SETUP_INSTRUCTIONS.txt > /etc/motd'

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
echo "Server will use ports ${config.serverStartPort} to $((${config.serverStartPort} + 8))"
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