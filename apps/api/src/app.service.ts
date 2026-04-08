import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getStatus() {
    return {
      name: 'SerceSync API',
      status: 'ok',
      phase: 'task-accountability',
    };
  }
}
