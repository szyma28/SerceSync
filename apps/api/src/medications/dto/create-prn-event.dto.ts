import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { MedicationAdministrationEventType } from '@prisma/client';

export class CreatePrnEventDto {
  @IsString()
  medicationOrderId!: string;

  @IsEnum(MedicationAdministrationEventType)
  eventType!: MedicationAdministrationEventType;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  doseGiven?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  doseUnit?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;

  @IsOptional()
  @IsString()
  witnessUserId?: string;
}
