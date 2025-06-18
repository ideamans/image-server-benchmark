import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';
import { BenchmarkConfig } from '../config-reader';

export interface BenchmarkNetworkProps {
  config: BenchmarkConfig;
}

export class BenchmarkNetwork extends Construct {
  public readonly vpc: ec2.Vpc;
  public readonly serverSecurityGroup: ec2.SecurityGroup;
  public readonly clientSecurityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, id: string, props: BenchmarkNetworkProps) {
    super(scope, id);

    const { config } = props;

    // VPC作成（パブリックサブネットのみ、シンプル構成）
    this.vpc = new ec2.Vpc(this, 'BenchmarkVPC', {
      vpcName: 'image-server-benchmark-vpc',
      maxAzs: 1,
      natGateways: 0,
      subnetConfiguration: [
        {
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
          cidrMask: 24,
        },
      ],
    });

    // サーバー用セキュリティグループ
    this.serverSecurityGroup = new ec2.SecurityGroup(this, 'ServerSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for benchmark server instance',
      securityGroupName: 'image-server-benchmark-server-sg',
    });

    // SSH接続を許可
    this.serverSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(22),
      'Allow SSH access'
    );

    // ベンチマークサーバーのポート範囲を開放
    const startPort = config.serverStartPort;
    const endPort = startPort + 8; // 9サーバー分

    this.serverSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcpRange(startPort, endPort),
      `Allow benchmark server ports ${startPort}-${endPort}`
    );

    // クライアントからのアクセスも許可（同一VPC内）
    this.serverSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(this.vpc.vpcCidrBlock),
      ec2.Port.allTraffic(),
      'Allow all traffic from within VPC'
    );

    // クライアント用セキュリティグループ
    this.clientSecurityGroup = new ec2.SecurityGroup(this, 'ClientSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for benchmark client instance',
      securityGroupName: 'image-server-benchmark-client-sg',
    });

    // SSH接続を許可
    this.clientSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(22),
      'Allow SSH access'
    );

    // アウトバウンドトラフィックは全て許可（デフォルト）
    // 特に制限する必要はない

    // タグ付け
    cdk.Tags.of(this.vpc).add('Project', 'image-server-benchmark');
    cdk.Tags.of(this.vpc).add('Component', 'network');
    cdk.Tags.of(this.serverSecurityGroup).add('Role', 'server');
    cdk.Tags.of(this.clientSecurityGroup).add('Role', 'client');
  }
}