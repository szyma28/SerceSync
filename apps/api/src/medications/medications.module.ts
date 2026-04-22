import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RolesGuard } from '../common/roles.guard';
import { ManagerDashboardStreamModule } from '../manager-dashboard-stream/manager-dashboard-stream.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ManagerMedicationsController } from './manager-medications.controller';
import { MedicationRoundsController } from './medication-rounds.controller';
import { MedicationOperationalSummaryService } from './medication-operational-summary.service';
import { MedicationsController } from './medications.controller';
import { MedicationsService } from './medications.service';
import { ResidentMedicationsController } from './resident-medications.controller';

@Module({
  imports: [AuthModule, PrismaModule, ManagerDashboardStreamModule],
  controllers: [
    ResidentMedicationsController,
    MedicationsController,
    MedicationRoundsController,
    ManagerMedicationsController,
  ],
  providers: [
    MedicationsService,
    MedicationOperationalSummaryService,
    RolesGuard,
  ],
  exports: [MedicationsService, MedicationOperationalSummaryService],
})
export class MedicationsModule {}
