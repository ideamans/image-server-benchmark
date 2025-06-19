import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface BenchmarkInstanceProps {
  vpc: ec2.Vpc;
  securityGroup: ec2.SecurityGroup;
  keyName: string;
  instanceType: ec2.InstanceType;
  userData: string;
  role: 'server' | 'client';
  availabilityZone?: string;
}

export class BenchmarkInstance extends Construct {
  public readonly instance: ec2.Instance;
  public readonly elasticIp: ec2.CfnEIP;

  constructor(scope: Construct, id: string, props: BenchmarkInstanceProps) {
    super(scope, id);

    // IAMロール（CloudWatch Logsへのアクセス権限）
    const role = new iam.Role(this, 'InstanceRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      roleName: `image-benchmark-${props.role}-role`,
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'), // Session Manager用
      ],
    });

    // ユーザーデータの作成
    const userDataScript = ec2.UserData.forLinux();
    userDataScript.addCommands(props.userData);

    // EC2インスタンス
    this.instance = new ec2.Instance(this, 'Instance', {
      vpc: props.vpc,
      instanceType: props.instanceType,
      machineImage: new ec2.AmazonLinuxImage({
        generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2023,
        cpuType: ec2.AmazonLinuxCpuType.ARM_64,
      }),
      keyName: props.keyName,
      securityGroup: props.securityGroup,
      role: role,
      userData: userDataScript,
      userDataCausesReplacement: true,
      availabilityZone: props.availabilityZone,
      blockDevices: [
        {
          deviceName: '/dev/xvda',
          volume: ec2.BlockDeviceVolume.ebs(30, {
            volumeType: ec2.EbsDeviceVolumeType.GP3,
            iops: 3000,
            throughput: 125, // MB/s
            deleteOnTermination: true,
          }),
        },
      ],
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    // インスタンス名タグ
    cdk.Tags.of(this.instance).add('Name', `image-benchmark-${props.role}`);
    cdk.Tags.of(this.instance).add('Role', props.role);

    // Elastic IP
    this.elasticIp = new ec2.CfnEIP(this, 'ElasticIP', {
      domain: 'vpc',
      instanceId: this.instance.instanceId,
      tags: [
        {
          key: 'Name',
          value: `image-benchmark-${props.role}-eip`,
        },
      ],
    });

    // Outputs
    new cdk.CfnOutput(this, `${props.role}InstanceId`, {
      value: this.instance.instanceId,
      description: `Instance ID of the ${props.role} instance`,
    });

    new cdk.CfnOutput(this, `${props.role}PublicIp`, {
      value: this.elasticIp.ref,
      description: `Public IP address of the ${props.role} instance`,
    });

    new cdk.CfnOutput(this, `${props.role}SshCommand`, {
      value: `ssh -i ~/.ssh/${props.keyName}.pem ec2-user@${this.elasticIp.ref}`,
      description: `SSH command to connect to the ${props.role} instance`,
    });
  }
}