import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ManagerDashboardStreamModule } from '../manager-dashboard-stream/manager-dashboard-stream.module';
import { PrismaModule } from '../prisma/prisma.module';
import { TasksController } from './tasks.controller';
import { TasksService } from './tasks.service';

@Module({
  imports: [AuthModule, PrismaModule, ManagerDashboardStreamModule],
  controllers: [TasksController],
  providers: [TasksService],
})
export class TasksModule {}
