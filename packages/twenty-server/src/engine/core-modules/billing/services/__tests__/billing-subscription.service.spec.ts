import { BillingEntitlementKey } from 'src/engine/core-modules/billing/enums/billing-entitlement-key.enum';
import { BillingSubscriptionService } from 'src/engine/core-modules/billing/services/billing-subscription.service';

type EntitlementRow = { value: boolean } | null;

const buildService = ({
  isValid,
  isBillingEnabled,
  entitlementRow,
}: {
  isValid: boolean;
  isBillingEnabled: boolean;
  entitlementRow?: EntitlementRow;
}) => {
  const enterprisePlanService = { isValid: jest.fn().mockReturnValue(isValid) };
  const twentyConfigService = {
    get: jest.fn().mockReturnValue(isBillingEnabled),
  };
  const billingEntitlementRepository = {
    findOne: jest.fn().mockResolvedValue(entitlementRow ?? null),
  };

  const noop = {};
  const args = [
    noop,
    noop,
    noop,
    noop,
    noop,
    billingEntitlementRepository,
    noop,
    noop,
    noop,
    twentyConfigService,
    noop,
    noop,
    noop,
    enterprisePlanService,
    noop,
    noop,
  ] as unknown as ConstructorParameters<typeof BillingSubscriptionService>;

  return {
    service: new BillingSubscriptionService(...args),
    billingEntitlementRepository,
  };
};

const getValue = (service: BillingSubscriptionService) =>
  service.getWorkspaceEntitlementValue(
    'workspace-1',
    BillingEntitlementKey.USAGE_LIMIT,
  );

describe('BillingSubscriptionService.getWorkspaceEntitlementValue', () => {
  it('is false without a valid Organization license (self-host OSS)', async () => {
    const { service, billingEntitlementRepository } = buildService({
      isValid: false,
      isBillingEnabled: false,
    });

    await expect(getValue(service)).resolves.toBe(false);
    expect(billingEntitlementRepository.findOne).not.toHaveBeenCalled();
  });

  it('is true on licensed self-host with billing disabled', async () => {
    const { service, billingEntitlementRepository } = buildService({
      isValid: true,
      isBillingEnabled: false,
    });

    await expect(getValue(service)).resolves.toBe(true);
    expect(billingEntitlementRepository.findOne).not.toHaveBeenCalled();
  });

  it('reads the Stripe entitlement row on cloud when the row is true', async () => {
    const { service } = buildService({
      isValid: true,
      isBillingEnabled: true,
      entitlementRow: { value: true },
    });

    await expect(getValue(service)).resolves.toBe(true);
  });

  it('is false on cloud when the Stripe entitlement row is false', async () => {
    const { service } = buildService({
      isValid: true,
      isBillingEnabled: true,
      entitlementRow: { value: false },
    });

    await expect(getValue(service)).resolves.toBe(false);
  });

  it('is false on cloud when no Stripe entitlement row exists', async () => {
    const { service } = buildService({
      isValid: true,
      isBillingEnabled: true,
      entitlementRow: null,
    });

    await expect(getValue(service)).resolves.toBe(false);
  });
});
