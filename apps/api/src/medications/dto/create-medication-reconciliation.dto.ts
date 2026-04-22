import {
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { MedicationReconciliationTriggerType } from '@prisma/client';

export class CreateMedicationReconciliationDto {
  @IsEnum(MedicationReconciliationTriggerType)
  triggerType!: MedicationReconciliationTriggerType;

  @IsOptional()
  @IsDateString()
  downtimeStartedAt?: string;

  @IsOptional()
  @IsDateString()
  downtimeEndedAt?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  paperRecordLocation?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
