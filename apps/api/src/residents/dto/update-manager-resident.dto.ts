import { ResidentPriorityLevel } from '@prisma/client';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class UpdateManagerResidentDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  fullName?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(999)
  roomNumber?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  floorNumber?: number;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  unitLabel?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  recognitionImageKey?: string;

  @IsOptional()
  @IsString()
  @MaxLength(800)
  careSummary?: string;

  @IsOptional()
  @IsEnum(ResidentPriorityLevel)
  baselinePriority?: ResidentPriorityLevel;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
