import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  ParseUUIDPipe,
  Patch,
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
import { RecordDoseOutcomeDto } from './dto/record-dose-outcome.dto';
import { UpdateDoseStatusDto } from './dto/update-dose-status.dto';
import { MedicationsService } from './medications.service';

@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class MedicationRoundsController {
  constructor(private readonly medicationsService: MedicationsService) {}

  @Post('shifts/:shiftId/generate-medication-round')
  @Roles('NURSE', 'MANAGER')
  generateMedicationRound(
    @Param('shiftId', new ParseUUIDPipe({ version: '4' })) shiftId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.medicationsService.generateMedicationRound(shiftId, user);
  }

  @Get('shifts/:shiftId/medication-round')
  @Roles('NURSE', 'MANAGER')
  getMedicationRound(
    @Param('shiftId', new ParseUUIDPipe({ version: '4' })) shiftId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.medicationsService.getMedicationRound(shiftId, user);
  }

  @Get('shifts/:shiftId/medication-round/export')
  @Roles('NURSE', 'MANAGER')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  async exportMedicationRound(
    @Param('shiftId', new ParseUUIDPipe({ version: '4' })) shiftId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Res({ passthrough: true }) response: Response,
  ) {
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="shift-${shiftId}-medication-round.csv"`,
    );
    return this.medicationsService.exportMedicationRoundCsv(shiftId, user);
  }

  @Patch('medication-dose-instances/:doseInstanceId/status')
  @Roles('NURSE')
  updateDoseStatus(
    @Param('doseInstanceId', new ParseUUIDPipe({ version: '4' }))
    doseInstanceId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateDoseStatusDto,
  ) {
    return this.medicationsService.updateDoseInstanceStatus(
      doseInstanceId,
      user,
      dto,
    );
  }

  @Post('medication-dose-instances/:doseInstanceId/administer')
  @Roles('NURSE')
  administerDose(
    @Param('doseInstanceId', new ParseUUIDPipe({ version: '4' }))
    doseInstanceId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RecordDoseOutcomeDto,
  ) {
    return this.medicationsService.administerDose(doseInstanceId, user, dto);
  }

  @Post('medication-dose-instances/:doseInstanceId/refuse')
  @Roles('NURSE')
  refuseDose(
    @Param('doseInstanceId', new ParseUUIDPipe({ version: '4' }))
    doseInstanceId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RecordDoseOutcomeDto,
  ) {
    return this.medicationsService.refuseDose(doseInstanceId, user, dto);
  }

  @Post('medication-dose-instances/:doseInstanceId/omit')
  @Roles('NURSE')
  omitDose(
    @Param('doseInstanceId', new ParseUUIDPipe({ version: '4' }))
    doseInstanceId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RecordDoseOutcomeDto,
  ) {
    return this.medicationsService.omitDose(doseInstanceId, user, dto);
  }

  @Post('medication-dose-instances/:doseInstanceId/delay')
  @Roles('NURSE')
  delayDose(
    @Param('doseInstanceId', new ParseUUIDPipe({ version: '4' }))
    doseInstanceId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RecordDoseOutcomeDto,
  ) {
    return this.medicationsService.delayDose(doseInstanceId, user, dto);
  }

  @Post('medication-dose-instances/:doseInstanceId/not-available')
  @Roles('NURSE')
  markDoseNotAvailable(
    @Param('doseInstanceId', new ParseUUIDPipe({ version: '4' }))
    doseInstanceId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RecordDoseOutcomeDto,
  ) {
    return this.medicationsService.markDoseNotAvailable(
      doseInstanceId,
      user,
      dto,
    );
  }
}
