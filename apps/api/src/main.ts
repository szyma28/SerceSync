import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { configureHttpApp } from './http-security';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  configureHttpApp(app);
  await app.listen(process.env.API_PORT ?? process.env.PORT ?? 3000);
}
bootstrap();
