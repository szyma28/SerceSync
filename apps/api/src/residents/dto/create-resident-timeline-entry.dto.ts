import { PersonalCareSubtype, ResidentTimelineEntryType } from '@prisma/client';
import {
  ValidateIf,
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

  @ValidateIf(
    (value: CreateResidentTimelineEntryDto) =>
      value.personalCareSubtype != null,
  )
  @IsEnum(PersonalCareSubtype)
  @IsOptional()
  personalCareSubtype?: PersonalCareSubtype;
}
