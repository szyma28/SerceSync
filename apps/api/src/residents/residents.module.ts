import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RolesGuard } from '../common/roles.guard';
import { PrismaModule } from '../prisma/prisma.module';
import { ManagerResidentsController } from './manager-residents.controller';
import { ResidentMediaController } from './resident-media.controller';
import { ResidentsController } from './residents.controller';
import { ResidentsService } from './residents.service';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [
    ResidentsController,
    ManagerResidentsController,
    ResidentMediaController,
  ],
  providers: [ResidentsService, RolesGuard],
})
export class ResidentsModule {}
