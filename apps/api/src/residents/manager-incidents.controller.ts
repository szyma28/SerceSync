import {
  Body,
  Controller,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { AcknowledgeManagerIncidentDto } from './dto/acknowledge-manager-incident.dto';
import { ResolveManagerIncidentDto } from './dto/resolve-manager-incident.dto';
import { ResidentsService } from './residents.service';

@Controller('manager/incidents')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('MANAGER')
export class ManagerIncidentsController {
  constructor(private readonly residentsService: ResidentsService) {}

  @Post(':id/acknowledge')
  @Throttle({
    default: {
      limit: 30,
      ttl: 60_000,
    },
  })
  acknowledgeIncident(
    @Param('id', new ParseUUIDPipe({ version: '4' })) incidentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() acknowledgeManagerIncidentDto: AcknowledgeManagerIncidentDto,
  ) {
    return this.residentsService.acknowledgeManagerIncident(
      incidentId,
      user,
      acknowledgeManagerIncidentDto.shiftId,
    );
  }

  @Post(':id/resolve')
  @Throttle({
    default: {
      limit: 30,
      ttl: 60_000,
    },
  })
  resolveIncident(
    @Param('id', new ParseUUIDPipe({ version: '4' })) incidentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() resolveManagerIncidentDto: ResolveManagerIncidentDto,
  ) {
    return this.residentsService.resolveManagerIncident(
      incidentId,
      user,
      resolveManagerIncidentDto.shiftId,
    );
  }
}
