import Fastify from 'fastify';
import fastifyStatic from '@fastify/static';
import { serverConfig, getServerPort, getProxyUrl } from '@benchmark/common/config-loader.js';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import fetch from 'node-fetch';

const __dirname = dirname(fileURLToPath(import.meta.url));
const imagesPath = resolve(__dirname, '../../../images');

const fastify = Fastify({
  logger: false,
  trustProxy: true,
  disableRequestLogging: true,
  caseSensitive: false,
  requestIdHeader: false,
  ignoreDuplicateSlashes: true,
});

// Register static file serving for local images
await fastify.register(fastifyStatic, {
  root: imagesPath,
  prefix: '/images/',
  cacheControl: false,
  etag: false,
  lastModified: false,
});

// Helper function to serve local images
async function serveLocalImage(request, reply, filename) {
  try {
    return reply.sendFile(filename);
  } catch (error) {
    reply.code(404).send({ error: 'Image not found' });
  }
}

// Helper function to proxy images
async function proxyImage(request, reply, imageName) {
  try {
    const url = getProxyUrl(imageName);
    const response = await fetch(url);
    
    if (!response.ok) {
      return reply.code(response.status).send({ error: `Upstream error: ${response.statusText}` });
    }
    
    // Forward content-type header
    const contentType = response.headers.get('content-type');
    if (contentType) {
      reply.header('content-type', contentType);
    }
    
    // Stream the response
    return reply.send(response.body);
  } catch (error) {
    console.error('Proxy error:', error);
    return reply.code(502).send({ error: 'Bad gateway' });
  }
}

// Local image endpoints
fastify.get('/local/20k', async (request, reply) => {
  return serveLocalImage(request, reply, '20k.jpg');
});

fastify.get('/local/50k', async (request, reply) => {
  return serveLocalImage(request, reply, '50k.jpg');
});

fastify.get('/local/100k', async (request, reply) => {
  return serveLocalImage(request, reply, '100k.jpg');
});

// Proxy image endpoints
fastify.get('/proxy/20k', async (request, reply) => {
  return proxyImage(request, reply, '20k.jpg');
});

fastify.get('/proxy/50k', async (request, reply) => {
  return proxyImage(request, reply, '50k.jpg');
});

fastify.get('/proxy/100k', async (request, reply) => {
  return proxyImage(request, reply, '100k.jpg');
});

// Health check endpoint
fastify.get('/health', async (request, reply) => {
  return { status: 'ok', server: 'fastify' };
});

// Start server
const start = async () => {
  try {
    const port = getServerPort(0); // Fastify uses offset 0
    await fastify.listen({ port, host: '0.0.0.0' });
    console.log(`Fastify server listening on port ${port}`);
  } catch (err) {
    console.error('Error starting server:', err);
    process.exit(1);
  }
};

start();