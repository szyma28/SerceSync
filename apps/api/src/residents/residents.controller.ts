import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import {
  isSafeResidentEvidenceUpload,
  residentEvidenceMaxUploadBytes,
} from './residents.constants';
import { CreateResidentIncidentDto } from './dto/create-resident-incident.dto';
import { CreateResidentTimelineEntryDto } from './dto/create-resident-timeline-entry.dto';
import { ResidentsService } from './residents.service';

const residentEvidenceUploadOptions = {
  limits: {
    fileSize: residentEvidenceMaxUploadBytes,
  },
  fileFilter: (
    _request: unknown,
    file: { mimetype: string; originalname: string },
    callback: (error: Error | null, acceptFile: boolean) => void,
  ) => {
    if (!isSafeResidentEvidenceUpload(file)) {
      callback(
        new BadRequestException(
          'Evidence uploads must be PNG, JPEG, or WebP images.',
        ),
        false,
      );
      return;
    }

    callback(null, true);
  },
} as const;

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
    @Param('id', new ParseUUIDPipe({ version: '4' })) residentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.residentsService.getResidentById(residentId, user);
  }

  @Post(':id/timeline')
  @Throttle({
    default: {
      limit: 20,
      ttl: 300_000,
    },
  })
  @UseInterceptors(FileInterceptor('evidence', residentEvidenceUploadOptions))
  createResidentTimelineEntry(
    @Param('id', new ParseUUIDPipe({ version: '4' })) residentId: string,
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
  @Throttle({
    default: {
      limit: 20,
      ttl: 300_000,
    },
  })
  @UseInterceptors(FileInterceptor('evidence', residentEvidenceUploadOptions))
  createResidentIncident(
    @Param('id', new ParseUUIDPipe({ version: '4' })) residentId: string,
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
