import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { CompleteTaskDto } from './dto/complete-task.dto';
import { TaskReasonDto } from './dto/task-reason.dto';
import { TasksService } from './tasks.service';

@Controller('tasks')
@UseGuards(JwtAuthGuard)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Get('current')
  getCurrentTasks(@CurrentUser() user: AuthenticatedUser) {
    return this.tasksService.getCurrentTasks(user);
  }

  @Post(':id/complete')
  completeTask(
    @Param('id') taskId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() completeTaskDto: CompleteTaskDto,
  ) {
    return this.tasksService.completeTask(taskId, user, completeTaskDto);
  }

  @Post(':id/defer')
  deferTask(
    @Param('id') taskId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() taskReasonDto: TaskReasonDto,
  ) {
    return this.tasksService.deferTask(taskId, user, taskReasonDto);
  }

  @Post(':id/escalate')
  escalateTask(
    @Param('id') taskId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() taskReasonDto: TaskReasonDto,
  ) {
    return this.tasksService.escalateTask(taskId, user, taskReasonDto);
  }
}
