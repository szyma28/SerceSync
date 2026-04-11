import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateManagerResidentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  fullName!: string;

  @IsInt()
  @Min(1)
  @Max(999)
  roomNumber!: number;

  @IsInt()
  @Min(1)
  @Max(20)
  floorNumber!: number;

  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  unitLabel!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  recognitionImageKey!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(800)
  careSummary!: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
