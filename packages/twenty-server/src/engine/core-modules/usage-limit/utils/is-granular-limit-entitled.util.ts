import { type UsageLimitEntitlementProvider } from 'src/engine/core-modules/usage-limit/interfaces/usage-limit-entitlement-provider.service';

export const isGranularLimitEntitled = async ({
  workspaceId,
  entitlementProvider,
}: {
  workspaceId: string;
  entitlementProvider: UsageLimitEntitlementProvider | null;
}): Promise<boolean> =>
  entitlementProvider
    ? entitlementProvider.hasGranularLimitEntitlement(workspaceId)
    : true;
