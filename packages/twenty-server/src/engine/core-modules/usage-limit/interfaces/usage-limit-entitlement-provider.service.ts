import { Injectable } from '@nestjs/common';

@Injectable()
export abstract class UsageLimitEntitlementProvider {
  abstract hasGranularLimitEntitlement(workspaceId: string): Promise<boolean>;
}
