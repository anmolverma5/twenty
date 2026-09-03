import { DiscoveryService } from '@nestjs/core';
import { Test, type TestingModule } from '@nestjs/testing';

import { ApiKeyEntity } from 'src/engine/core-modules/api-key/api-key.entity';
import { ApplicationEntity } from 'src/engine/core-modules/application/application.entity';
import { type UpsertUsageLimitInput } from 'src/engine/core-modules/usage-limit/dtos/upsert-usage-limit.input';
import { UsageLimitExceptionCode } from 'src/engine/core-modules/usage-limit/exceptions/usage-limit.exception';
import { UsageLimitEntitlementProvider } from 'src/engine/core-modules/usage-limit/interfaces/usage-limit-entitlement-provider.service';
import { UsageLimitQuotaService } from 'src/engine/core-modules/usage-limit/services/usage-limit-quota.service';
import { UsageLimitService } from 'src/engine/core-modules/usage-limit/services/usage-limit.service';
import { UsageLimitEntity } from 'src/engine/core-modules/usage-limit/usage-limit.entity';
import { UsageOperationType } from 'src/engine/core-modules/usage/enums/usage-operation-type.enum';
import { UsageResourceType } from 'src/engine/core-modules/usage/enums/usage-resource-type.enum';
import { UserWorkspaceEntity } from 'src/engine/core-modules/user-workspace/user-workspace.entity';
import { AgentEntity } from 'src/engine/metadata-modules/ai/ai-agent/entities/agent.entity';
import { LogicFunctionEntity } from 'src/engine/metadata-modules/logic-function/logic-function.entity';
import { getWorkspaceScopedRepositoryToken } from 'src/engine/twenty-orm/workspace-scoped-repository/get-workspace-scoped-repository-token.util';
import { WorkspaceCacheService } from 'src/engine/workspace-cache/services/workspace-cache.service';

class TestUsageLimitEntitlementProvider extends UsageLimitEntitlementProvider {
  hasGranularLimitEntitlement = jest.fn();
}

const granularInput: UpsertUsageLimitInput = {
  resourceType: UsageResourceType.API,
  operationType: UsageOperationType.API_REQUEST,
  spenderType: 'apiKey',
  spenderId: null,
  limitKind: 'speed',
  periodCount: 60,
  periodUnit: 'second',
  meter: 'quantity',
  limitValue: 100,
};

const workspaceInput: UpsertUsageLimitInput = {
  resourceType: UsageResourceType.AI,
  operationType: UsageOperationType.AI_CHAT_TOKEN,
  spenderType: 'workspace',
  spenderId: null,
  limitKind: 'quota',
  periodCount: 1,
  periodUnit: 'month',
  meter: 'creditsUsedMicro',
  limitValue: 1_000_000,
};

describe('UsageLimitService', () => {
  const usageLimitRepository = {
    upsert: jest.fn().mockResolvedValue(undefined),
    findOneOrFail: jest.fn().mockResolvedValue({ id: 'limit-1' }),
    findOne: jest.fn(),
    delete: jest.fn().mockResolvedValue({ affected: 1 }),
  };
  const workspaceCacheService = {
    invalidateAndRecompute: jest.fn().mockResolvedValue(undefined),
  };
  const usageLimitQuotaService = {
    dropLimitCounter: jest.fn().mockResolvedValue(undefined),
  };

  const buildService = async (
    provider: TestUsageLimitEntitlementProvider | null,
  ) => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsageLimitService,
        {
          provide: getWorkspaceScopedRepositoryToken(UsageLimitEntity),
          useValue: usageLimitRepository,
        },
        {
          provide: getWorkspaceScopedRepositoryToken(ApiKeyEntity),
          useValue: { existsBy: jest.fn().mockResolvedValue(true) },
        },
        {
          provide: getWorkspaceScopedRepositoryToken(ApplicationEntity),
          useValue: {},
        },
        {
          provide: getWorkspaceScopedRepositoryToken(UserWorkspaceEntity),
          useValue: {},
        },
        {
          provide: getWorkspaceScopedRepositoryToken(AgentEntity),
          useValue: {},
        },
        {
          provide: getWorkspaceScopedRepositoryToken(LogicFunctionEntity),
          useValue: {},
        },
        { provide: WorkspaceCacheService, useValue: workspaceCacheService },
        { provide: UsageLimitQuotaService, useValue: usageLimitQuotaService },
        {
          provide: DiscoveryService,
          useValue: {
            getProviders: () => (provider ? [{ instance: provider }] : []),
          },
        },
      ],
    }).compile();

    const service = module.get<UsageLimitService>(UsageLimitService);

    service.onModuleInit();

    return service;
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('rejects a granular upsert when the workspace is not entitled', async () => {
    const provider = new TestUsageLimitEntitlementProvider();

    provider.hasGranularLimitEntitlement.mockResolvedValue(false);
    const service = await buildService(provider);

    await expect(
      service.upsert({ workspaceId: 'workspace-1', input: granularInput }),
    ).rejects.toMatchObject({
      code: UsageLimitExceptionCode.LIMIT_NOT_ENTITLED,
    });
    expect(usageLimitRepository.upsert).not.toHaveBeenCalled();
  });

  it('accepts a workspace-scope upsert when the workspace is not entitled', async () => {
    const provider = new TestUsageLimitEntitlementProvider();

    provider.hasGranularLimitEntitlement.mockResolvedValue(false);
    const service = await buildService(provider);

    await service.upsert({ workspaceId: 'workspace-1', input: workspaceInput });

    expect(provider.hasGranularLimitEntitlement).not.toHaveBeenCalled();
    expect(usageLimitRepository.upsert).toHaveBeenCalledTimes(1);
  });

  it('accepts a granular upsert when the workspace is entitled', async () => {
    const provider = new TestUsageLimitEntitlementProvider();

    provider.hasGranularLimitEntitlement.mockResolvedValue(true);
    const service = await buildService(provider);

    await service.upsert({ workspaceId: 'workspace-1', input: granularInput });

    expect(usageLimitRepository.upsert).toHaveBeenCalledTimes(1);
  });

  it('accepts a granular upsert when no entitlement provider is registered', async () => {
    const service = await buildService(null);

    await service.upsert({ workspaceId: 'workspace-1', input: granularInput });

    expect(usageLimitRepository.upsert).toHaveBeenCalledTimes(1);
  });

  it('deletes a leftover granular row even when not entitled', async () => {
    const provider = new TestUsageLimitEntitlementProvider();

    provider.hasGranularLimitEntitlement.mockResolvedValue(false);
    usageLimitRepository.findOne.mockResolvedValue({
      id: 'limit-1',
      spenderType: 'apiKey',
    });
    const service = await buildService(provider);

    await expect(
      service.delete({ workspaceId: 'workspace-1', usageLimitId: 'limit-1' }),
    ).resolves.toBe(true);
    expect(provider.hasGranularLimitEntitlement).not.toHaveBeenCalled();
  });
});
