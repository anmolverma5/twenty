import { type UsageLimitEntitlementProvider } from 'src/engine/core-modules/usage-limit/interfaces/usage-limit-entitlement-provider.service';
import { type FlatUsageLimit } from 'src/engine/core-modules/usage-limit/types/flat-usage-limit.type';
import { type SpenderType } from 'src/engine/core-modules/usage-limit/types/spender-type.type';
import { findEnforceableLimits } from 'src/engine/core-modules/usage-limit/utils/find-enforceable-limits.util';
import { UsageOperationType } from 'src/engine/core-modules/usage/enums/usage-operation-type.enum';
import { UsageResourceType } from 'src/engine/core-modules/usage/enums/usage-resource-type.enum';

const buildLimit = (spenderType: SpenderType, id: string): FlatUsageLimit => ({
  id,
  resourceType: UsageResourceType.API,
  operationType: UsageOperationType.API_REQUEST,
  spenderType,
  spenderId: '',
  limitKind: 'quota',
  periodCount: 1,
  periodUnit: 'month',
  meter: 'quantity',
  limitValue: 100,
  burstValue: null,
});

const buildProvider = (
  entitled: boolean,
): UsageLimitEntitlementProvider & {
  hasGranularLimitEntitlement: jest.Mock;
} => ({
  hasGranularLimitEntitlement: jest.fn().mockResolvedValue(entitled),
});

describe('findEnforceableLimits', () => {
  const workspaceLimit = buildLimit('workspace', 'ws');
  const userWorkspaceLimit = buildLimit('userWorkspace', 'uw');

  it('returns limits untouched and never awaits the provider when no granular row exists', async () => {
    const provider = buildProvider(false);

    const result = await findEnforceableLimits({
      workspaceId: 'workspace-1',
      limits: [workspaceLimit],
      entitlementProvider: provider,
    });

    expect(result).toEqual([workspaceLimit]);
    expect(provider.hasGranularLimitEntitlement).not.toHaveBeenCalled();
  });

  it('keeps granular rows when no provider is registered', async () => {
    const result = await findEnforceableLimits({
      workspaceId: 'workspace-1',
      limits: [workspaceLimit, userWorkspaceLimit],
      entitlementProvider: null,
    });

    expect(result).toEqual([workspaceLimit, userWorkspaceLimit]);
  });

  it('keeps granular rows when the workspace is entitled', async () => {
    const provider = buildProvider(true);

    const result = await findEnforceableLimits({
      workspaceId: 'workspace-1',
      limits: [workspaceLimit, userWorkspaceLimit],
      entitlementProvider: provider,
    });

    expect(result).toEqual([workspaceLimit, userWorkspaceLimit]);
    expect(provider.hasGranularLimitEntitlement).toHaveBeenCalledWith(
      'workspace-1',
    );
  });

  it('drops granular rows and keeps workspace-scope rows when not entitled', async () => {
    const provider = buildProvider(false);

    const result = await findEnforceableLimits({
      workspaceId: 'workspace-1',
      limits: [workspaceLimit, userWorkspaceLimit],
      entitlementProvider: provider,
    });

    expect(result).toEqual([workspaceLimit]);
  });
});
