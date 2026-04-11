import { ResidentTimelineEntryType } from '@prisma/client';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class CreateResidentTimelineEntryDto {
  @IsEnum(ResidentTimelineEntryType)
  type!: ResidentTimelineEntryType;

  @IsString()
  @IsOptional()
  @MaxLength(120)
  title?: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  details!: string;
}
