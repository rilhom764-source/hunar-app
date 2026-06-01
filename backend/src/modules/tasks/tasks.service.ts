// ============================================================================
// Tasks Service - NestJS Backend Architecture
// ============================================================================
// This is the backend service stub for the Tasks module
// using NestJS + Prisma ORM + PostgreSQL

import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.service';
import { TaskStatus } from '@prisma/client';

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  // ── CREATE ──────────────────────────────────────────────
  async createTask(clientId: string, dto: CreateTaskDto) {
    return this.prisma.task.create({
      data: {
        title: dto.title,
        description: dto.description,
        category: dto.category,
        budget: dto.budget,
        location: dto.location,
        latitude: dto.latitude,
        longitude: dto.longitude,
        deadline: new Date(dto.deadline),
        voiceMessageUrl: dto.voiceMessageUrl,
        clientId,
      },
      include: { client: { select: { id: true, fullName: true, avatarUrl: true } } },
    });
  }

  // ── READ (with Haversine geolocation filter) ───────────
  async findNearby(lat: number, lon: number, radiusKm: number, filters?: TaskFilters) {
    // Haversine formula in raw SQL for performance
    const tasks = await this.prisma.$queryRaw`
      SELECT *,
        (6371 * acos(
          cos(radians(${lat})) * cos(radians(latitude)) *
          cos(radians(longitude) - radians(${lon})) +
          sin(radians(${lat})) * sin(radians(latitude))
        )) AS distance_km
      FROM tasks
      WHERE status = 'OPEN'
        AND (6371 * acos(
          cos(radians(${lat})) * cos(radians(latitude)) *
          cos(radians(longitude) - radians(${lon})) +
          sin(radians(${lat})) * sin(radians(latitude))
        )) <= ${radiusKm}
      ORDER BY distance_km ASC
      LIMIT 50
    `;
    return tasks;
  }

  async findAll(page: number = 1, limit: number = 20, filters?: TaskFilters) {
    const skip = (page - 1) * limit;
    const where: any = {};
    
    if (filters?.status) where.status = filters.status;
    if (filters?.category) where.category = filters.category;
    if (filters?.clientId) where.clientId = filters.clientId;

    const [tasks, total] = await Promise.all([
      this.prisma.task.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          client: { select: { id: true, fullName: true, avatarUrl: true, rating: true } },
          _count: { select: { bids: true } },
        },
      }),
      this.prisma.task.count({ where }),
    ]);

    return { tasks, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findById(id: string) {
    const task = await this.prisma.task.findUnique({
      where: { id },
      include: {
        client: { select: { id: true, fullName: true, avatarUrl: true, phone: true, rating: true } },
        assignedWorker: { select: { id: true, fullName: true, avatarUrl: true, phone: true, rating: true } },
        bids: {
          include: { worker: { select: { id: true, fullName: true, avatarUrl: true, rating: true, tasksCompleted: true } } },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!task) throw new NotFoundException('Task not found');
    return task;
  }

  // ── UPDATE ─────────────────────────────────────────────
  async updateTask(id: string, userId: string, dto: UpdateTaskDto) {
    const task = await this.prisma.task.findUnique({ where: { id } });
    if (!task) throw new NotFoundException('Task not found');
    if (task.clientId !== userId) throw new ForbiddenException('Not task owner');
    
    return this.prisma.task.update({
      where: { id },
      data: dto,
    });
  }

  // ── STATUS LIFECYCLE ───────────────────────────────────
  // Open -> In Progress -> Completed
  async advanceStatus(id: string, userId: string) {
    const task = await this.prisma.task.findUnique({ where: { id } });
    if (!task) throw new NotFoundException('Task not found');
    if (task.clientId !== userId) throw new ForbiddenException('Not task owner');

    const transitions: Record<string, TaskStatus> = {
      'OPEN': 'IN_PROGRESS',
      'IN_PROGRESS': 'COMPLETED',
    };

    const newStatus = transitions[task.status];
    if (!newStatus) throw new ForbiddenException(`Cannot advance from ${task.status}`);

    const updated = await this.prisma.task.update({
      where: { id },
      data: {
        status: newStatus,
        ...(newStatus === 'COMPLETED' ? { completedAt: new Date() } : {}),
      },
    });

    // If completed, update worker stats
    if (newStatus === 'COMPLETED' && task.assignedWorkerId) {
      await this.prisma.user.update({
        where: { id: task.assignedWorkerId },
        data: { tasksCompleted: { increment: 1 } },
      });
    }

    return updated;
  }

  // ── DELETE ─────────────────────────────────────────────
  async deleteTask(id: string, userId: string) {
    const task = await this.prisma.task.findUnique({ where: { id } });
    if (!task) throw new NotFoundException('Task not found');
    if (task.clientId !== userId) throw new ForbiddenException('Not task owner');
    if (task.status !== 'OPEN') throw new ForbiddenException('Can only delete open tasks');

    return this.prisma.task.delete({ where: { id } });
  }
}

// ── DTOs ───────────────────────────────────────────────────
interface CreateTaskDto {
  title: string;
  description: string;
  category: string;
  budget: number;
  location: string;
  latitude: number;
  longitude: number;
  deadline: string;
  voiceMessageUrl?: string;
}

interface UpdateTaskDto {
  title?: string;
  description?: string;
  category?: string;
  budget?: number;
  location?: string;
  deadline?: string;
}

interface TaskFilters {
  status?: TaskStatus;
  category?: string;
  clientId?: string;
}
