import { Elysia } from 'elysia';
import { serverConfig, getServerPort, getProxyUrl } from '@benchmark/common/config-loader.js';
import { readFile } from 'fs/promises';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const imagesPath = resolve(__dirname, '../../../images');

const app = new Elysia();

// Helper function to serve local images
async function serveLocalImage(filename: string) {
  try {
    const imagePath = resolve(imagesPath, filename);
    const imageData = await readFile(imagePath);
    return new Response(imageData, {
      headers: {
        'Content-Type': 'image/jpeg'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Image not found' }), {
      status: 404,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}

// Helper function to proxy images
async function proxyImage(imageName: string) {
  try {
    const url = getProxyUrl(imageName);
    const response = await fetch(url);
    
    if (!response.ok) {
      return new Response(JSON.stringify({ error: `Upstream error: ${response.statusText}` }), {
        status: response.status,
        headers: {
          'Content-Type': 'application/json'
        }
      });
    }
    
    // Get the response body as blob
    const blob = await response.blob();
    
    // Forward content-type header
    const headers: HeadersInit = {};
    const contentType = response.headers.get('content-type');
    if (contentType) {
      headers['Content-Type'] = contentType;
    }
    
    return new Response(blob, { headers });
  } catch (error) {
    console.error('Proxy error:', error);
    return new Response(JSON.stringify({ error: 'Bad gateway' }), {
      status: 502,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}

// Local image endpoints
app.get('/local/20k', () => serveLocalImage('20k.jpg'));
app.get('/local/50k', () => serveLocalImage('50k.jpg'));
app.get('/local/100k', () => serveLocalImage('100k.jpg'));

// Proxy image endpoints
app.get('/proxy/20k', () => proxyImage('20k.jpg'));
app.get('/proxy/50k', () => proxyImage('50k.jpg'));
app.get('/proxy/100k', () => proxyImage('100k.jpg'));

// Health check endpoint
app.get('/health', () => ({
  status: 'ok',
  server: 'elysia'
}));

// Start server
const port = getServerPort(2); // Elysia uses offset 2

app.listen({
  port: port,
  hostname: '0.0.0.0'
});

console.log(`Elysia server listening on port ${port}`);