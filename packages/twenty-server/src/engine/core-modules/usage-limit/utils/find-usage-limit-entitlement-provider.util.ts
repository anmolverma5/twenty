import { type DiscoveryService } from '@nestjs/core';

import { isDefined } from 'twenty-shared/utils';

import { UsageLimitEntitlementProvider } from 'src/engine/core-modules/usage-limit/interfaces/usage-limit-entitlement-provider.service';

export const findUsageLimitEntitlementProvider = (
  discoveryService: DiscoveryService,
): UsageLimitEntitlementProvider | null => {
  for (const wrapper of discoveryService.getProviders()) {
    const { instance } = wrapper;

    if (
      isDefined(instance) &&
      instance instanceof UsageLimitEntitlementProvider
    ) {
      return instance;
    }
  }

  return null;
};
