import {
  MealIntakeAmount,
  MealType,
  PersonalCareSubtype,
  ResidentTimelineEntryType,
} from '@prisma/client';
import {
  ValidateIf,
  IsEnum,
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
  @IsOptional()
  @MaxLength(2000)
  details?: string;

  @ValidateIf(
    (value: CreateResidentTimelineEntryDto) =>
      value.personalCareSubtype != null,
  )
  @IsEnum(PersonalCareSubtype)
  @IsOptional()
  personalCareSubtype?: PersonalCareSubtype;

  @ValidateIf((value: CreateResidentTimelineEntryDto) => value.mealType != null)
  @IsEnum(MealType)
  @IsOptional()
  mealType?: MealType;

  @ValidateIf(
    (value: CreateResidentTimelineEntryDto) => value.mealIntakeAmount != null,
  )
  @IsEnum(MealIntakeAmount)
  @IsOptional()
  mealIntakeAmount?: MealIntakeAmount;
}
