import { randomUUID } from 'crypto';
import { Injectable, MessageEvent } from '@nestjs/common';
import { Observable } from 'rxjs';

type ManagerDashboardStreamEventType = 'stream.connected' | 'dashboard.updated';

export type ManagerDashboardUpdateReason =
  | 'timeline-entry-created'
  | 'incident-created'
  | 'incident-acknowledged'
  | 'incident-resolved'
  | 'task-completed'
  | 'task-deferred'
  | 'task-escalated';

interface ManagerDashboardStreamPayload {
  type: ManagerDashboardStreamEventType;
  shiftId: string;
  eventId: string;
  occurredAt: string;
  reason: ManagerDashboardUpdateReason | 'connected';
}

@Injectable()
export class ManagerDashboardStreamService {
  private readonly listeners = new Map<
    string,
    Set<(payload: ManagerDashboardStreamPayload) => void>
  >();

  streamForShift(shiftId: string): Observable<MessageEvent> {
    return new Observable<MessageEvent>((subscriber) => {
      subscriber.next({
        data: this.createPayload(shiftId, 'stream.connected', 'connected'),
      });

      const unsubscribe = this.subscribe(shiftId, (payload) => {
        subscriber.next({ data: payload });
      });

      return () => unsubscribe();
    });
  }

  publishShiftUpdate(shiftId: string, reason: ManagerDashboardUpdateReason) {
    const listeners = this.listeners.get(shiftId);
    if (!listeners || listeners.size == 0) {
      return;
    }

    const payload = this.createPayload(shiftId, 'dashboard.updated', reason);
    for (const listener of listeners) {
      listener(payload);
    }
  }

  private subscribe(
    shiftId: string,
    listener: (payload: ManagerDashboardStreamPayload) => void,
  ) {
    const listeners = this.listeners.get(shiftId) ?? new Set();
    listeners.add(listener);
    this.listeners.set(shiftId, listeners);

    return () => {
      const currentListeners = this.listeners.get(shiftId);
      if (!currentListeners) {
        return;
      }

      currentListeners.delete(listener);
      if (currentListeners.size === 0) {
        this.listeners.delete(shiftId);
      }
    };
  }

  private createPayload(
    shiftId: string,
    type: ManagerDashboardStreamEventType,
    reason: ManagerDashboardUpdateReason | 'connected',
  ): ManagerDashboardStreamPayload {
    return {
      type,
      shiftId,
      eventId: randomUUID(),
      occurredAt: new Date().toISOString(),
      reason,
    };
  }
}
