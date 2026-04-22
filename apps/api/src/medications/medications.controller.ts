import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { CreateMedicationScheduleDto } from './dto/create-medication-schedule.dto';
import { CreateMedicationStockTransactionDto } from './dto/create-medication-stock-transaction.dto';
import { CreatePrnProtocolDto } from './dto/create-prn-protocol.dto';
import { DeactivateMedicationOrderDto } from './dto/deactivate-medication-order.dto';
import { DeactivateMedicationScheduleDto } from './dto/deactivate-medication-schedule.dto';
import { UpdateMedicationOrderDto } from './dto/update-medication-order.dto';
import { UpdateMedicationScheduleDto } from './dto/update-medication-schedule.dto';
import { UpdatePrnProtocolDto } from './dto/update-prn-protocol.dto';
import { MedicationsService } from './medications.service';

@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class MedicationsController {
  constructor(private readonly medicationsService: MedicationsService) {}

  @Patch('medications/:medicationOrderId')
  @Roles('MANAGER')
  updateMedicationOrder(
    @Param('medicationOrderId', new ParseUUIDPipe({ version: '4' }))
    medicationOrderId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateMedicationOrderDto,
  ) {
    return this.medicationsService.updateMedicationOrder(
      medicationOrderId,
      user,
      dto,
    );
  }

  @Post('medications/:medicationOrderId/deactivate')
  @Roles('MANAGER')
  deactivateMedicationOrder(
    @Param('medicationOrderId', new ParseUUIDPipe({ version: '4' }))
    medicationOrderId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: DeactivateMedicationOrderDto,
  ) {
    return this.medicationsService.deactivateMedicationOrder(
      medicationOrderId,
      user,
      dto,
    );
  }

  @Post('medications/:medicationOrderId/schedules')
  @Roles('MANAGER')
  createMedicationSchedule(
    @Param('medicationOrderId', new ParseUUIDPipe({ version: '4' }))
    medicationOrderId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateMedicationScheduleDto,
  ) {
    return this.medicationsService.createMedicationSchedule(
      medicationOrderId,
      user,
      dto,
    );
  }

  @Patch('medication-schedules/:scheduleId')
  @Roles('MANAGER')
  updateMedicationSchedule(
    @Param('scheduleId', new ParseUUIDPipe({ version: '4' }))
    scheduleId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateMedicationScheduleDto,
  ) {
    return this.medicationsService.updateMedicationSchedule(
      scheduleId,
      user,
      dto,
    );
  }

  @Post('medication-schedules/:scheduleId/deactivate')
  @Roles('MANAGER')
  deactivateMedicationSchedule(
    @Param('scheduleId', new ParseUUIDPipe({ version: '4' }))
    scheduleId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: DeactivateMedicationScheduleDto,
  ) {
    return this.medicationsService.deactivateMedicationSchedule(
      scheduleId,
      user,
      dto,
    );
  }

  @Post('medications/:medicationOrderId/prn-protocol')
  @Roles('MANAGER')
  createPrnProtocol(
    @Param('medicationOrderId', new ParseUUIDPipe({ version: '4' }))
    medicationOrderId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePrnProtocolDto,
  ) {
    return this.medicationsService.createPrnProtocol(
      medicationOrderId,
      user,
      dto,
    );
  }

  @Patch('prn-protocols/:prnProtocolId')
  @Roles('MANAGER')
  updatePrnProtocol(
    @Param('prnProtocolId', new ParseUUIDPipe({ version: '4' }))
    prnProtocolId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdatePrnProtocolDto,
  ) {
    return this.medicationsService.updatePrnProtocol(prnProtocolId, user, dto);
  }

  @Get('medications/:medicationOrderId/stock')
  @Roles('NURSE', 'MANAGER')
  getMedicationStock(
    @Param('medicationOrderId', new ParseUUIDPipe({ version: '4' }))
    medicationOrderId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.medicationsService.getMedicationStock(medicationOrderId, user);
  }

  @Post('medications/:medicationOrderId/stock-transactions')
  @Roles('NURSE', 'MANAGER')
  createMedicationStockTransaction(
    @Param('medicationOrderId', new ParseUUIDPipe({ version: '4' }))
    medicationOrderId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateMedicationStockTransactionDto,
  ) {
    return this.medicationsService.createStockTransaction(
      medicationOrderId,
      user,
      dto,
    );
  }
}
