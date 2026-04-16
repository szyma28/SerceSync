import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { CreateResidentIncidentDto } from './dto/create-resident-incident.dto';
import { CreateResidentTimelineEntryDto } from './dto/create-resident-timeline-entry.dto';
import { ResidentsService } from './residents.service';

@Controller('residents')
@UseGuards(JwtAuthGuard)
export class ResidentsController {
  constructor(private readonly residentsService: ResidentsService) {}

  @Get()
  getResidents(@CurrentUser() user: AuthenticatedUser) {
    return this.residentsService.getResidents(user);
  }

  @Get(':id')
  getResidentById(
    @Param('id') residentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.residentsService.getResidentById(residentId, user);
  }

  @Post(':id/timeline')
  @UseInterceptors(
    FileInterceptor('evidence', {
      limits: {
        fileSize: 6 * 1024 * 1024,
      },
    }),
  )
  createResidentTimelineEntry(
    @Param('id') residentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() createResidentTimelineEntryDto: CreateResidentTimelineEntryDto,
    @UploadedFile()
    evidenceFile?: {
      buffer: Buffer;
      originalname: string;
      mimetype: string;
      size: number;
    },
  ) {
    return this.residentsService.createResidentTimelineEntry(
      residentId,
      user,
      createResidentTimelineEntryDto,
      evidenceFile,
    );
  }

  @Post(':id/incidents')
  @UseInterceptors(
    FileInterceptor('evidence', {
      limits: {
        fileSize: 6 * 1024 * 1024,
      },
    }),
  )
  createResidentIncident(
    @Param('id') residentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() createResidentIncidentDto: CreateResidentIncidentDto,
    @UploadedFile()
    evidenceFile?: {
      buffer: Buffer;
      originalname: string;
      mimetype: string;
      size: number;
    },
  ) {
    return this.residentsService.createResidentIncident(
      residentId,
      user,
      createResidentIncidentDto,
      evidenceFile,
    );
  }
}
