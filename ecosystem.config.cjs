// PM2 Ecosystem configuration for Twenty CRM
// Usage in WSL (from /home/nfs/twenty or /home/nfs/projects/vezpec-sales-crm):
//   pm2 start ecosystem.config.cjs
//   pm2 save
//   pm2 status
//   pm2 logs

const path = require('path');

const repoRoot = __dirname;
const serverDir = path.join(repoRoot, 'packages', 'twenty-server');

module.exports = {
  apps: [
    {
      name: 'twenty-server',
      cwd: serverDir,
      script: 'dist/main.js',
      exec_mode: 'fork',
      interpreter: 'node',
      autorestart: true,
      watch: false,
      max_memory_restart: '1500M',
      env: {
        NODE_ENV: 'development',
        PORT: '3010',
        NODE_PORT: '3010',
        SERVER_URL: 'https://twenty-api.vezpec.com',
        FRONTEND_URL: 'https://twenty.vezpec.com',
      },
      time: true,
    },
    {
      name: 'twenty-worker',
      cwd: serverDir,
      script: 'dist/queue-worker/queue-worker.js',
      exec_mode: 'fork',
      interpreter: 'node',
      autorestart: true,
      watch: false,
      max_memory_restart: '1000M',
      env: {
        NODE_ENV: 'development',
        SERVER_URL: 'https://twenty-api.vezpec.com',
      },
      time: true,
    },
    {
      name: 'twenty-front',
      cwd: repoRoot,
      script: './node_modules/.bin/nx',
      args: 'run twenty-front:start',
      exec_mode: 'fork',
      interpreter: 'node',
      autorestart: true,
      watch: false,
      max_memory_restart: '2000M',
      env: {
        NODE_ENV: 'development',
        REACT_APP_PORT: '3011',
        REACT_APP_SERVER_BASE_URL: 'https://twenty-api.vezpec.com',
        VITE_HOST: '0.0.0.0',
      },
      time: true,
    },
  ],
};
