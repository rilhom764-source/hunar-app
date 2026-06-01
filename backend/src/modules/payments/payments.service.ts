// ============================================================================
// Payments Service - NestJS Backend with Tajikistan Gateway Stubs
// ============================================================================
// Integration stubs for Alif Mobi and DC Next payment gateways

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma.service';
import { PaymentMethod, PaymentStatus } from '@prisma/client';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  // ── PROCESS PAYMENT ─────────────────────────────────────
  async processPayment(dto: ProcessPaymentDto) {
    // Create transaction record
    const transaction = await this.prisma.transaction.create({
      data: {
        amount: dto.amount,
        method: dto.method,
        status: 'PROCESSING',
        taskId: dto.taskId,
        payerId: dto.payerId,
        payeeId: dto.payeeId,
        platformFee: dto.amount * 0.10, // 10% platform commission
        platformFeePercent: 10,
      },
    });

    try {
      let gatewayResult: GatewayResult;

      switch (dto.method) {
        case 'ALIF_MOBI':
          gatewayResult = await this.processAlifMobi(transaction.id, dto);
          break;
        case 'DC_NEXT':
          gatewayResult = await this.processDCNext(transaction.id, dto);
          break;
        case 'CASH':
          gatewayResult = { success: true, transactionId: `CASH-${Date.now()}` };
          break;
        default:
          gatewayResult = { success: false, error: 'Unsupported payment method' };
      }

      // Update transaction with result
      return this.prisma.transaction.update({
        where: { id: transaction.id },
        data: {
          status: gatewayResult.success ? 'COMPLETED' : 'FAILED',
          externalTransactionId: gatewayResult.transactionId,
          gatewayResponse: gatewayResult as any,
          completedAt: gatewayResult.success ? new Date() : null,
        },
      });
    } catch (error) {
      // Mark transaction as failed
      await this.prisma.transaction.update({
        where: { id: transaction.id },
        data: { status: 'FAILED', gatewayResponse: { error: String(error) } },
      });
      throw error;
    }
  }

  // ── ALIF MOBI INTEGRATION STUB ──────────────────────────
  // Production: Replace with actual Alif Mobi API calls
  // API endpoint: https://api.alifmobi.tj/v1/payments
  private async processAlifMobi(txId: string, dto: ProcessPaymentDto): Promise<GatewayResult> {
    console.log(`[AlifMobi] Processing payment: ${dto.amount} TJS`);
    
    // STUB: Simulate Alif Mobi P2P transfer API
    // In production, implement:
    //
    // 1. Authentication:
    //    POST https://api.alifmobi.tj/v1/auth/token
    //    Body: { client_id, client_secret, grant_type: "client_credentials" }
    //
    // 2. Create P2P transfer:
    //    POST https://api.alifmobi.tj/v1/payments/p2p
    //    Headers: { Authorization: Bearer <token> }
    //    Body: {
    //      amount: dto.amount,
    //      currency: "TJS",
    //      sender_phone: dto.senderPhone,
    //      receiver_phone: dto.receiverPhone,
    //      description: `Usto Connect Task Payment #${txId}`,
    //      callback_url: "https://api.ustoconnect.tj/webhooks/alif"
    //    }
    //
    // 3. Handle callback for payment confirmation
    //    POST /webhooks/alif -> verify signature -> update transaction status

    await new Promise(resolve => setTimeout(resolve, 1500));
    
    return {
      success: true,
      transactionId: `ALF-${Date.now()}`,
      gateway: 'alif_mobi',
    };
  }

  // ── DC NEXT INTEGRATION STUB ────────────────────────────
  // Production: Replace with actual DC Next API calls
  // API endpoint: https://api.dc.tj/v2/transfers
  private async processDCNext(txId: string, dto: ProcessPaymentDto): Promise<GatewayResult> {
    console.log(`[DCNext] Processing payment: ${dto.amount} TJS`);
    
    // STUB: Simulate DC Next wallet transfer API
    // In production, implement:
    //
    // 1. Merchant authentication:
    //    POST https://api.dc.tj/v2/auth
    //    Headers: { X-Merchant-Id: <id>, X-API-Key: <key> }
    //
    // 2. Create transfer:
    //    POST https://api.dc.tj/v2/transfers
    //    Body: {
    //      amount: dto.amount,
    //      currency: "TJS",
    //      from_wallet: dto.senderAccount,
    //      to_wallet: dto.receiverAccount,
    //      reference: `USTO-${txId}`,
    //      webhook_url: "https://api.ustoconnect.tj/webhooks/dc-next"
    //    }
    //
    // 3. Handle webhook for transfer confirmation
    //    POST /webhooks/dc-next -> verify HMAC -> update transaction status

    await new Promise(resolve => setTimeout(resolve, 1500));
    
    return {
      success: true,
      transactionId: `DC-${Date.now()}`,
      gateway: 'dc_next',
    };
  }

  // ── WEBHOOK HANDLERS ────────────────────────────────────
  async handleAlifWebhook(payload: any) {
    // Verify webhook signature
    // Update transaction status based on callback
    const txId = payload.reference;
    if (payload.status === 'success') {
      await this.prisma.transaction.update({
        where: { externalTransactionId: payload.transaction_id },
        data: { status: 'COMPLETED', completedAt: new Date() },
      });
    }
  }

  async handleDCNextWebhook(payload: any) {
    // Verify HMAC signature
    // Update transaction status based on webhook
    if (payload.event === 'transfer.completed') {
      await this.prisma.transaction.update({
        where: { externalTransactionId: payload.transfer_id },
        data: { status: 'COMPLETED', completedAt: new Date() },
      });
    }
  }

  // ── TRANSACTION HISTORY ─────────────────────────────────
  async getUserTransactions(userId: string) {
    return this.prisma.transaction.findMany({
      where: { OR: [{ payerId: userId }, { payeeId: userId }] },
      include: {
        task: { select: { id: true, title: true } },
        payer: { select: { id: true, fullName: true } },
        payee: { select: { id: true, fullName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}

// ── Interfaces ──────────────────────────────────────────────
interface ProcessPaymentDto {
  amount: number;
  method: PaymentMethod;
  taskId: string;
  payerId: string;
  payeeId: string;
  senderPhone?: string;
  receiverPhone?: string;
  senderAccount?: string;
  receiverAccount?: string;
}

interface GatewayResult {
  success: boolean;
  transactionId?: string;
  gateway?: string;
  error?: string;
}
