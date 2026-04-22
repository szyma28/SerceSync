import {
  IsArray,
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

export class CreateMedicationScheduleDto {
  @IsEnum(MedicationRoundLabel)
  roundLabel!: MedicationRoundLabel;

  @IsEnum(MedicationScheduleAnchorType)
  anchorType!: MedicationScheduleAnchorType;

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
}
