import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { validateEnvironment } from './config/environment.validation';
import { HandoversModule } from './handovers/handovers.module';
import { MedicationsModule } from './medications/medications.module';
import { PrismaModule } from './prisma/prisma.module';
import { ResidentsModule } from './residents/residents.module';
import { ShiftsModule } from './shifts/shifts.module';
import { TasksModule } from './tasks/tasks.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '../../.env'],
      validate: validateEnvironment,
    }),
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60_000,
        limit: 600,
      },
    ]),
    AuthModule,
    ShiftsModule,
    HandoversModule,
    TasksModule,
    ResidentsModule,
    MedicationsModule,
    PrismaModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
