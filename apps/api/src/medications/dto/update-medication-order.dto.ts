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

export class UpdateMedicationOrderDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(160)
  medicationName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  formulation?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  strength?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  doseAmount?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  doseUnit?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  route?: string;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  instructions?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string | null;

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
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsEnum(MedicationOrderSourceType)
  sourceType?: MedicationOrderSourceType;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
