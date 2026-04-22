import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { MedicationOrderSourceType } from '@prisma/client';

export class CreateMedicationOrderDto {
  @IsString()
  @MinLength(2)
  @MaxLength(160)
  medicationName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  formulation?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  strength?: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  doseAmount!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(40)
  doseUnit!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(80)
  route!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  instructions!: string;

  @IsDateString()
  startDate!: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsBoolean()
  isControlledDrug?: boolean;

  @IsOptional()
  @IsBoolean()
  requiresWitness?: boolean;

  @IsOptional()
  @IsBoolean()
  isPRN?: boolean;

  @IsOptional()
  @IsEnum(MedicationOrderSourceType)
  sourceType?: MedicationOrderSourceType;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  changeReason?: string;
}
