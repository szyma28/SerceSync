import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MedicationsModule } from '../medications/medications.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ShiftsController } from './shifts.controller';
import { ShiftsService } from './shifts.service';

@Module({
  imports: [AuthModule, PrismaModule, MedicationsModule],
  controllers: [ShiftsController],
  providers: [ShiftsService],
  exports: [ShiftsService],
})
export class ShiftsModule {}
