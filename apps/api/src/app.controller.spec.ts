import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [AppService],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return the task accountability status payload', () => {
      expect(appController.getStatus()).toEqual({
        name: 'SerceSync API',
        status: 'ok',
        phase: 'task-accountability',
      });
    });
  });
});
