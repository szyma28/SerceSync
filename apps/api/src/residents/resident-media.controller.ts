import {
  Controller,
  Get,
  Param,
  Res,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import { createReadStream } from 'fs';
import type { Response } from 'express';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { ResidentsService } from './residents.service';

@Controller('resident-media')
@UseGuards(JwtAuthGuard)
export class ResidentMediaController {
  constructor(private readonly residentsService: ResidentsService) {}

  @Get(':id')
  async getResidentMedia(
    @Param('id') mediaId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Res({ passthrough: true }) response: Response,
  ) {
    const media = await this.residentsService.getResidentMedia(mediaId, user);

    response.setHeader('Content-Type', media.mediaType);
    response.setHeader(
      'Content-Disposition',
      `inline; filename="${media.originalFileName}"`,
    );

    return new StreamableFile(createReadStream(media.storagePath));
  }
}
