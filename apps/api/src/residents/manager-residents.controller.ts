import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { CreateManagerResidentDto } from './dto/create-manager-resident.dto';
import { UpdateManagerResidentDto } from './dto/update-manager-resident.dto';
import { ResidentsService } from './residents.service';

@Controller('manager/residents')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('MANAGER')
export class ManagerResidentsController {
  constructor(private readonly residentsService: ResidentsService) {}

  @Get()
  getResidents() {
    return this.residentsService.getManagerResidents();
  }

  @Post()
  createResident(@Body() createManagerResidentDto: CreateManagerResidentDto) {
    return this.residentsService.createManagerResident(
      createManagerResidentDto,
    );
  }

  @Patch(':id')
  updateResident(
    @Param('id') residentId: string,
    @Body() updateManagerResidentDto: UpdateManagerResidentDto,
  ) {
    return this.residentsService.updateManagerResident(
      residentId,
      updateManagerResidentDto,
    );
  }
}
