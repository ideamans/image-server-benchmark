import { config } from 'dotenv';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load .env from project root
config({ path: resolve(__dirname, '../../.env') });

export const serverConfig = {
  originUrlBase: process.env.ORIGIN_URL || process.env.ORIGIN_URL_BASE || 'http://localhost:8080/',
  serverStartPort: parseInt(process.env.SERVER_START_PORT || '3001'),
  workerThreads: parseInt(process.env.SERVER_WORKER_THREADS || '0'),
};

export function getServerPort(offset) {
  return serverConfig.serverStartPort + offset;
}

export function getProxyUrl(imageName) {
  return `${serverConfig.originUrlBase}${imageName}`;
}