import { type AllMetadataName } from 'twenty-shared/metadata';
import { isDefined } from 'twenty-shared/utils';

import { NATURAL_KEY_PROPERTIES_BY_METADATA_NAME } from 'src/engine/metadata-modules/flat-entity/constant/natural-key-properties-by-metadata-name.constant';

type FlatEntityWithUniversalIdentifier = {
  universalIdentifier: string;
} & Record<string, unknown>;

type FlatEntityMapsByUniversalIdentifier = {
  byUniversalIdentifier: Partial<
    Record<string, FlatEntityWithUniversalIdentifier>
  >;
};

const computeNaturalKey = (
  flatEntity: FlatEntityWithUniversalIdentifier,
  naturalKeyProperties: string[],
): string =>
  JSON.stringify(naturalKeyProperties.map((property) => flatEntity[property]));

export const keepExistingIdentifiersByNaturalKey = <
  TFlatEntityMaps extends FlatEntityMapsByUniversalIdentifier,
>({
  metadataName,
  fromFlatEntityMaps,
  toFlatEntityMaps,
}: {
  metadataName: AllMetadataName;
  fromFlatEntityMaps: TFlatEntityMaps;
  toFlatEntityMaps: TFlatEntityMaps;
}): TFlatEntityMaps => {
  const naturalKeyProperties: string[] | undefined =
    NATURAL_KEY_PROPERTIES_BY_METADATA_NAME[metadataName];

  if (!isDefined(naturalKeyProperties)) {
    return toFlatEntityMaps;
  }

  const fromUniversalIdentifierByNaturalKey = new Map<string, string>();

  for (const fromFlatEntity of Object.values(
    fromFlatEntityMaps.byUniversalIdentifier,
  )) {
    if (!isDefined(fromFlatEntity)) {
      continue;
    }

    fromUniversalIdentifierByNaturalKey.set(
      computeNaturalKey(fromFlatEntity, naturalKeyProperties),
      fromFlatEntity.universalIdentifier,
    );
  }

  const byUniversalIdentifier = { ...toFlatEntityMaps.byUniversalIdentifier };

  for (const toFlatEntity of Object.values(
    toFlatEntityMaps.byUniversalIdentifier,
  )) {
    if (!isDefined(toFlatEntity)) {
      continue;
    }

    const existingUniversalIdentifier = fromUniversalIdentifierByNaturalKey.get(
      computeNaturalKey(toFlatEntity, naturalKeyProperties),
    );

    if (
      !isDefined(existingUniversalIdentifier) ||
      existingUniversalIdentifier === toFlatEntity.universalIdentifier ||
      isDefined(byUniversalIdentifier[existingUniversalIdentifier])
    ) {
      continue;
    }

    delete byUniversalIdentifier[toFlatEntity.universalIdentifier];
    byUniversalIdentifier[existingUniversalIdentifier] = {
      ...toFlatEntity,
      universalIdentifier: existingUniversalIdentifier,
    };
  }

  return { ...toFlatEntityMaps, byUniversalIdentifier };
};
