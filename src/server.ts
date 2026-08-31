import 'reflect-metadata';
import * as dotenv from 'dotenv';
dotenv.config();

import app from './app';
import { AppDataSource } from './config/data-source';

const PORT = Number(process.env.PORT) || 3000;

async function bootstrap() {
  try {
    await AppDataSource.initialize();
    console.log('✅ Database connection established');

    const server = app.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
    });

    const shutdown = async (signal: string) => {
      console.log(`\n${signal} received. Shutting down gracefully...`);
      server.close(async () => {
        await AppDataSource.destroy();
        console.log('Database connection closed. Bye!');
        process.exit(0);
      });
    };

    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
  } catch (err) {
    console.error('❌ Failed to start the application:', err);
    process.exit(1);
  }
}

bootstrap();
