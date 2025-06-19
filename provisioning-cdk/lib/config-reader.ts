import * as dotenv from "dotenv";
import * as path from "path";

export interface BenchmarkConfig {
  // AWS設定
  keyPairName: string;
  awsRegion: string;
  awsProfile?: string;

  // インスタンス設定
  serverInstanceType: string;
  clientInstanceType: string;

  // アプリケーション設定
  originUrlBase: string;
  serverStartPort: number;
  serverWorkerThreads: number;

  // ベンチマーク設定
  benchmarkDuration: string;
  benchmarkWarmupDuration: string;
  benchmarkCooldownDuration: string;
  maxVus: number;
  errorThreshold: number;
  responseTimeThreshold: number;
}

export class ConfigReader {
  static loadConfig(): BenchmarkConfig {
    // プロジェクトルートの.envファイルを読み込み
    const envPath = path.resolve(__dirname, "../../.env");
    dotenv.config({ path: envPath });

    // 環境変数から設定を取得（デフォルト値付き）
    const config: BenchmarkConfig = {
      // AWS設定
      keyPairName: process.env.KEY_PAIR_NAME || "",
      awsRegion: process.env.AWS_REGION || "us-east-1",
      awsProfile: process.env.AWS_PROFILE,

      // インスタンス設定
      serverInstanceType: process.env.SERVER_INSTANCE_TYPE || "m6g.medium",
      clientInstanceType: process.env.CLIENT_INSTANCE_TYPE || "m6g.4xlarge",

      // アプリケーション設定
      originUrlBase:
        process.env.ORIGIN_URL ||
        process.env.ORIGIN_URL_BASE ||
        "http://localhost:8080/",
      serverStartPort: parseInt(process.env.SERVER_START_PORT || "3001"),
      serverWorkerThreads: parseInt(process.env.SERVER_WORKER_THREADS || "0"),

      // ベンチマーク設定
      benchmarkDuration: process.env.BENCHMARK_DURATION || "60s",
      benchmarkWarmupDuration: process.env.BENCHMARK_WARMUP_DURATION || "10s",
      benchmarkCooldownDuration:
        process.env.BENCHMARK_COOLDOWN_DURATION || "10s",
      maxVus: parseInt(process.env.MAX_VUS || "200"),
      errorThreshold: parseFloat(process.env.ERROR_THRESHOLD || "0.01"),
      responseTimeThreshold: parseInt(
        process.env.RESPONSE_TIME_THRESHOLD || "1000"
      ),
    };

    return config;
  }

  static validateConfig(config: BenchmarkConfig): void {
    const errors: string[] = [];

    // キーペア名の検証（CDKパラメータで指定される場合もあるので必須ではない）
    // if (!config.keyPairName) {
    //   errors.push('KEY_PAIR_NAME is not set in .env file');
    // }

    // Origin URLの検証
    if (!config.originUrlBase) {
      errors.push("ORIGIN_URL or ORIGIN_URL_BASE is not set in .env file");
    }

    // ポート番号の検証
    if (config.serverStartPort < 1024 || config.serverStartPort > 65535) {
      errors.push("SERVER_START_PORT must be between 1024 and 65535");
    }

    // インスタンスタイプの検証
    const validInstanceTypes =
      /^[a-z]\d+[a-z]?\.(micro|small|medium|large|\d*x?large)$/;
    if (!validInstanceTypes.test(config.serverInstanceType)) {
      console.warn(
        `Warning: Unusual server instance type: ${config.serverInstanceType}`
      );
    }
    if (!validInstanceTypes.test(config.clientInstanceType)) {
      console.warn(
        `Warning: Unusual client instance type: ${config.clientInstanceType}`
      );
    }

    if (errors.length > 0) {
      throw new Error("Configuration validation failed:\n" + errors.join("\n"));
    }
  }
}

// コマンドラインから直接実行された場合は設定を出力
if (require.main === module) {
  try {
    const config = ConfigReader.loadConfig();
    ConfigReader.validateConfig(config);
    console.log("Loaded configuration:");
    console.log(JSON.stringify(config, null, 2));
  } catch (error) {
    console.error("Error loading configuration:", error);
    process.exit(1);
  }
}
