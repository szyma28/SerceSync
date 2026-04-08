import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CompleteTaskDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
