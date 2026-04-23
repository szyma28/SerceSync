import { IncidentCategory, IncidentSeverity } from '@prisma/client';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateResidentIncidentDto {
  @IsEnum(IncidentSeverity)
  severity!: IncidentSeverity;

  @IsEnum(IncidentCategory)
  category!: IncidentCategory;

  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  title!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  details!: string;

  @IsOptional()
  @IsDateString()
  occurredAt?: string;

  @IsOptional()
  @IsUUID()
  clientRequestId?: string;
}
