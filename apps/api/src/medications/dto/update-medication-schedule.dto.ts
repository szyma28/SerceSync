import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';
import {
  MedicationRoundLabel,
  MedicationScheduleAnchorType,
} from '@prisma/client';

export class UpdateMedicationScheduleDto {
  @IsOptional()
  @IsEnum(MedicationRoundLabel)
  roundLabel?: MedicationRoundLabel;

  @IsOptional()
  @IsEnum(MedicationScheduleAnchorType)
  anchorType?: MedicationScheduleAnchorType;

  @IsOptional()
  @IsInt()
  @Min(0)
  windowStartOffsetMinutes?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  windowEndOffsetMinutes?: number;

  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/)
  fixedTimeLocal?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @MaxLength(12, { each: true })
  daysOfWeek?: string[];

  @IsOptional()
  @IsBoolean()
  active?: boolean;

  @IsString()
  @MaxLength(500)
  reason!: string;
}
