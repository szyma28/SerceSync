import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  ParseUUIDPipe,
  Post,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { CreateMedicationAllergyDto } from './dto/create-medication-allergy.dto';
import { CreateMedicationOrderDto } from './dto/create-medication-order.dto';
import { CreateMedicationReconciliationDto } from './dto/create-medication-reconciliation.dto';
import { CreatePrnEventDto } from './dto/create-prn-event.dto';
import { CompleteMedicationReconciliationDto } from './dto/complete-medication-reconciliation.dto';
import { MedicationsService } from './medications.service';

@Controller('residents')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ResidentMedicationsController {
  constructor(private readonly medicationsService: MedicationsService) {}

  @Get(':residentId/emar')
  @Roles('NURSE', 'MANAGER')
  getResidentEmar(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.medicationsService.getResidentEmar(residentId, user);
  }

  @Get(':residentId/medications')
  @Roles('NURSE', 'MANAGER')
  getResidentMedications(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.medicationsService.getResidentMedications(residentId, user);
  }

  @Get(':residentId/medication-events')
  @Roles('NURSE', 'MANAGER')
  getResidentMedicationEvents(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.medicationsService.getResidentMedicationEvents(
      residentId,
      user,
    );
  }

  @Get(':residentId/medication-reconciliations')
  @Roles('NURSE', 'MANAGER')
  getResidentMedicationReconciliations(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.medicationsService.getResidentMedicationReconciliations(
      residentId,
      user,
    );
  }

  @Post(':residentId/medications')
  @Roles('MANAGER')
  createMedicationOrder(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateMedicationOrderDto,
  ) {
    return this.medicationsService.createMedicationOrder(residentId, user, dto);
  }

  @Post(':residentId/prn-events')
  @Roles('NURSE')
  createPrnEvent(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePrnEventDto,
  ) {
    return this.medicationsService.recordPrnEvent(residentId, user, dto);
  }

  @Post(':residentId/medication-allergies')
  @Roles('MANAGER')
  createMedicationAllergy(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateMedicationAllergyDto,
  ) {
    return this.medicationsService.recordMedicationAllergy(
      residentId,
      user,
      dto,
    );
  }

  @Post(':residentId/medication-reconciliations')
  @Roles('MANAGER')
  createMedicationReconciliation(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateMedicationReconciliationDto,
  ) {
    return this.medicationsService.createMedicationReconciliation(
      residentId,
      user,
      dto,
    );
  }

  @Post('medication-reconciliations/:reconciliationId/complete')
  @Roles('MANAGER')
  completeMedicationReconciliation(
    @Param('reconciliationId', new ParseUUIDPipe({ version: '4' }))
    reconciliationId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CompleteMedicationReconciliationDto,
  ) {
    return this.medicationsService.completeMedicationReconciliation(
      reconciliationId,
      user,
      dto,
    );
  }

  @Get(':residentId/emar/export')
  @Roles('NURSE', 'MANAGER')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  async exportResidentEmar(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Res({ passthrough: true }) response: Response,
  ) {
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="resident-${residentId}-emar.csv"`,
    );
    return this.medicationsService.exportResidentEmarCsv(residentId, user);
  }

  @Get(':residentId/emar/downtime-pack/export')
  @Roles('NURSE', 'MANAGER')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  async exportResidentDowntimePack(
    @Param('residentId', new ParseUUIDPipe({ version: '4' }))
    residentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Res({ passthrough: true }) response: Response,
  ) {
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="resident-${residentId}-emar-downtime-pack.csv"`,
    );
    return this.medicationsService.exportResidentDowntimePackCsv(
      residentId,
      user,
    );
  }
}
