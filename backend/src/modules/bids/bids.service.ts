// ============================================================================
// Bids Service - NestJS Backend Architecture
// ============================================================================

import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.service';
import { BidStatus } from '@prisma/client';

@Injectable()
export class BidsService {
  constructor(private readonly prisma: PrismaService) {}

  // ── PLACE BID ──────────────────────────────────────────
  async placeBid(workerId: string, dto: PlaceBidDto) {
    const task = await this.prisma.task.findUnique({ where: { id: dto.taskId } });
    if (!task) throw new NotFoundException('Task not found');
    if (task.status !== 'OPEN') throw new ForbiddenException('Task is not open for bids');
    if (task.clientId === workerId) throw new ForbiddenException('Cannot bid on own task');

    // Check if worker already placed a bid
    const existingBid = await this.prisma.bid.findUnique({
      where: { taskId_workerId: { taskId: dto.taskId, workerId } },
    });
    if (existingBid) throw new ConflictException('Already placed a bid on this task');

    const bid = await this.prisma.bid.create({
      data: {
        amount: dto.amount,
        message: dto.message,
        estimatedTime: dto.estimatedTime,
        taskId: dto.taskId,
        workerId,
      },
      include: {
        worker: { select: { id: true, fullName: true, avatarUrl: true, rating: true, tasksCompleted: true } },
      },
    });

    // Update bids count on task
    await this.prisma.task.update({
      where: { id: dto.taskId },
      data: { bidsCount: { increment: 1 } },
    });

    return bid;
  }

  // ── ACCEPT BID ─────────────────────────────────────────
  async acceptBid(bidId: string, clientId: string) {
    const bid = await this.prisma.bid.findUnique({
      where: { id: bidId },
      include: { task: true },
    });

    if (!bid) throw new NotFoundException('Bid not found');
    if (bid.task.clientId !== clientId) throw new ForbiddenException('Not task owner');
    if (bid.task.status !== 'OPEN') throw new ForbiddenException('Task is not open');

    // Accept this bid, reject all others
    await this.prisma.$transaction([
      // Accept the selected bid
      this.prisma.bid.update({
        where: { id: bidId },
        data: { status: 'ACCEPTED' },
      }),
      // Reject all other bids for this task
      this.prisma.bid.updateMany({
        where: { taskId: bid.taskId, id: { not: bidId } },
        data: { status: 'REJECTED' },
      }),
      // Update task: assign worker, change status
      this.prisma.task.update({
        where: { id: bid.taskId },
        data: {
          status: 'IN_PROGRESS',
          assignedWorkerId: bid.workerId,
        },
      }),
    ]);

    return { message: 'Bid accepted successfully' };
  }

  // ── GET BIDS FOR TASK ──────────────────────────────────
  async getBidsForTask(taskId: string) {
    return this.prisma.bid.findMany({
      where: { taskId },
      include: {
        worker: {
          select: { id: true, fullName: true, avatarUrl: true, rating: true, tasksCompleted: true, reviewsCount: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ── GET WORKER'S BIDS ─────────────────────────────────
  async getWorkerBids(workerId: string, status?: BidStatus) {
    return this.prisma.bid.findMany({
      where: { workerId, ...(status ? { status } : {}) },
      include: {
        task: {
          select: { id: true, title: true, budget: true, location: true, status: true, category: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}

// ── DTOs ───────────────────────────────────────────────────
interface PlaceBidDto {
  taskId: string;
  amount: number;
  message: string;
  estimatedTime: string;
}
