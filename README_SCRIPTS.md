# スクリプト一覧

## メインスクリプト（ルートディレクトリ）

### セットアップ
- `setup-amazon-linux.sh` - Amazon Linux 2023で全環境をセットアップ

### 実行
- `start-servers.sh` - 全サーバーを起動（ポート3001-3009）
- `run-benchmark.sh` - k6ベンチマークを実行
- `stop-servers.sh` - 全サーバーを停止

### Docker
- `run-amazon-linux.sh` - Amazon Linux 2023のDockerコンテナを起動

### メンテナンス
- `clean-servers.sh` - ビルド成果物をクリーンアップ

## ユーティリティ（scripts/utils/）

- `load-env.sh` - .envファイルを読み込む共通処理

## 使用例

```bash
# Amazon Linux環境でのセットアップと実行
./run-amazon-linux.sh         # Dockerコンテナに入る
./setup-amazon-linux.sh       # 環境構築（初回のみ）
./start-servers.sh           # サーバー起動

# 別のマシンからベンチマーク実行
echo "SERVER_IP=10.0.0.1" >> .env
./run-benchmark.sh
```