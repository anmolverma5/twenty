import { type UsageLimitEntitlementProvider } from 'src/engine/core-modules/usage-limit/interfaces/usage-limit-entitlement-provider.service';
import { type FlatUsageLimit } from 'src/engine/core-modules/usage-limit/types/flat-usage-limit.type';
import { isGranularLimitEntitled } from 'src/engine/core-modules/usage-limit/utils/is-granular-limit-entitled.util';
import { isGranularSpenderType } from 'src/engine/core-modules/usage-limit/utils/is-granular-spender-type.util';

export const findEnforceableLimits = async ({
  workspaceId,
  limits,
  entitlementProvider,
}: {
  workspaceId: string;
  limits: FlatUsageLimit[];
  entitlementProvider: UsageLimitEntitlementProvider | null;
}): Promise<FlatUsageLimit[]> => {
  if (!limits.some((limit) => isGranularSpenderType(limit.spenderType))) {
    return limits;
  }

  if (await isGranularLimitEntitled({ workspaceId, entitlementProvider })) {
    return limits;
  }

  return limits.filter((limit) => !isGranularSpenderType(limit.spenderType));
};
