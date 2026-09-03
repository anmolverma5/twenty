import { BillingEntitlementKey } from 'src/engine/core-modules/billing/enums/billing-entitlement-key.enum';
import { type BillingSubscriptionService } from 'src/engine/core-modules/billing/services/billing-subscription.service';
import { BillingUsageLimitEntitlementProvider } from 'src/engine/core-modules/billing/services/billing-usage-limit-entitlement-provider.service';

describe('BillingUsageLimitEntitlementProvider', () => {
  const buildProvider = (getWorkspaceEntitlementValue: jest.Mock) =>
    new BillingUsageLimitEntitlementProvider({
      getWorkspaceEntitlementValue,
    } as unknown as BillingSubscriptionService);

  it('delegates to the USAGE_LIMIT entitlement value', async () => {
    const getWorkspaceEntitlementValue = jest.fn().mockResolvedValue(true);
    const provider = buildProvider(getWorkspaceEntitlementValue);

    await expect(
      provider.hasGranularLimitEntitlement('workspace-1'),
    ).resolves.toBe(true);
    expect(getWorkspaceEntitlementValue).toHaveBeenCalledWith(
      'workspace-1',
      BillingEntitlementKey.USAGE_LIMIT,
    );
  });

  it('returns the negative value when the workspace is not entitled', async () => {
    const provider = buildProvider(jest.fn().mockResolvedValue(false));

    await expect(
      provider.hasGranularLimitEntitlement('workspace-1'),
    ).resolves.toBe(false);
  });

  it('fails open so a lookup failure never drops configured limits', async () => {
    const provider = buildProvider(
      jest.fn().mockRejectedValue(new Error('stripe unreachable')),
    );

    await expect(
      provider.hasGranularLimitEntitlement('workspace-1'),
    ).resolves.toBe(true);
  });
});
