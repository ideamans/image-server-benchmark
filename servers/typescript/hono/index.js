import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import { serverConfig, getServerPort, getProxyUrl } from '@benchmark/common/config-loader.js';
import { readFile } from 'fs/promises';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import fetch from 'node-fetch';

const __dirname = dirname(fileURLToPath(import.meta.url));
const imagesPath = resolve(__dirname, '../../../images');

const app = new Hono();

// Helper function to serve local images
async function serveLocalImage(c, filename) {
  try {
    const imagePath = resolve(imagesPath, filename);
    const imageData = await readFile(imagePath);
    c.header('Content-Type', 'image/jpeg');
    return c.body(imageData);
  } catch (error) {
    return c.json({ error: 'Image not found' }, 404);
  }
}

// Helper function to proxy images
async function proxyImage(c, imageName) {
  try {
    const url = getProxyUrl(imageName);
    const response = await fetch(url);
    
    if (!response.ok) {
      return c.json({ error: `Upstream error: ${response.statusText}` }, response.status);
    }
    
    // Get the response body as buffer
    const buffer = await response.buffer();
    
    // Forward content-type header
    const contentType = response.headers.get('content-type');
    if (contentType) {
      c.header('Content-Type', contentType);
    }
    
    return c.body(buffer);
  } catch (error) {
    console.error('Proxy error:', error);
    return c.json({ error: 'Bad gateway' }, 502);
  }
}

// Local image endpoints
app.get('/local/20k', async (c) => {
  return serveLocalImage(c, '20k.jpg');
});

app.get('/local/50k', async (c) => {
  return serveLocalImage(c, '50k.jpg');
});

app.get('/local/100k', async (c) => {
  return serveLocalImage(c, '100k.jpg');
});

// Proxy image endpoints
app.get('/proxy/20k', async (c) => {
  return proxyImage(c, '20k.jpg');
});

app.get('/proxy/50k', async (c) => {
  return proxyImage(c, '50k.jpg');
});

app.get('/proxy/100k', async (c) => {
  return proxyImage(c, '100k.jpg');
});

// Health check endpoint
app.get('/health', (c) => {
  return c.json({ status: 'ok', server: 'hono' });
});

// Start server
const port = getServerPort(1); // Hono uses offset 1
console.log(`Hono server listening on port ${port}`);

serve({
  fetch: app.fetch,
  port: port,
  hostname: '0.0.0.0'
});