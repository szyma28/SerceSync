import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
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

  private sanitizeDownloadFileName(fileName: string) {
    const normalized = fileName.trim().replace(/[^a-zA-Z0-9._ -]/g, '_');
    return normalized.length > 0 ? normalized : 'resident-evidence';
  }

  @Get(':id')
  async getResidentMedia(
    @Param('id', new ParseUUIDPipe({ version: '4' })) mediaId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Res({ passthrough: true }) response: Response,
  ) {
    const media = await this.residentsService.getResidentMedia(mediaId, user);
    const safeFileName = this.sanitizeDownloadFileName(media.originalFileName);

    response.setHeader('Content-Type', media.mediaType);
    response.setHeader('X-Content-Type-Options', 'nosniff');
    response.setHeader('Cache-Control', 'private, no-store, max-age=0');
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${safeFileName}"`,
    );

    return new StreamableFile(createReadStream(media.storagePath));
  }
}
