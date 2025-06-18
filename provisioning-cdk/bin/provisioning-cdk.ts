#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { ImageServerBenchmarkStack } from '../lib/benchmark-stack';
import { ConfigReader } from '../lib/config-reader';

const app = new cdk.App();

// 設定を読み込み
const config = ConfigReader.loadConfig();

// スタック名（環境変数から取得可能）
const stackName = process.env.CDK_STACK_NAME || 'ImageServerBenchmarkStack';

// スタックの作成
new ImageServerBenchmarkStack(app, stackName, {
  /* スタックプロパティ */
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: config.awsRegion || process.env.CDK_DEFAULT_REGION,
  },
  description: 'Image Server Benchmark infrastructure for performance testing',
  stackName: stackName,
  
  /* タグ */
  tags: {
    Project: 'image-server-benchmark',
    ManagedBy: 'cdk',
    Repository: 'https://github.com/idaemans/image-server-benchmark',
  },
});

// スタック合成
app.synth();