import { Controller, Get, Header, Query, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { MedicationsService } from './medications.service';

@Controller('manager')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('MANAGER')
export class ManagerMedicationsController {
  constructor(private readonly medicationsService: MedicationsService) {}

  @Get('medication-exceptions')
  getMedicationExceptions(
    @CurrentUser() user: AuthenticatedUser,
    @Query('shiftId') shiftId?: string,
  ) {
    return this.medicationsService.getManagerMedicationExceptions(
      shiftId,
      user,
    );
  }

  @Get('overdue-medication')
  getOverdueMedication(@Query('shiftId') shiftId?: string) {
    return this.medicationsService.getManagerOverdueMedication(shiftId);
  }

  @Get('medication-audit')
  getMedicationAudit(@CurrentUser() user: AuthenticatedUser) {
    void user;
    return this.medicationsService.getManagerMedicationAudit();
  }

  @Get('medication-reconciliation-queue')
  getMedicationReconciliationQueue(@CurrentUser() user: AuthenticatedUser) {
    return this.medicationsService.getManagerMedicationReconciliationQueue(
      user,
    );
  }

  @Get('medication-audit/export')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  async exportMedicationAudit(@Res({ passthrough: true }) response: Response) {
    response.setHeader(
      'Content-Disposition',
      'attachment; filename="medication-audit.csv"',
    );
    return this.medicationsService.exportMedicationAuditCsv();
  }
}
