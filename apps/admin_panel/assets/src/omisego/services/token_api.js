import request from './api_service';

export function getAll(params) {
  const {
    per, sort, query, ...rest
  } = params;
  const requestParams = {
    path: 'minted_token.all',
    params: JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    authenticated: true,
  };
  return request(requestParams);
}

export function create(params) {
  const {
    isoCode,
    shortSymbol,
    subUnit,
    subUnitToUnit,
    symbolFirst,
    htmlEntity,
    isoNumeric,
    smallestDenomination,
    ...rest
  } = params;
  const requestParams = {
    path: 'minted_token.create',
    params: JSON.stringify({
      iso_code: isoCode,
      short_symbol: shortSymbol,
      subunit: subUnit,
      subunit_to_unit: parseInt(subUnitToUnit, 0),
      symbol_first: symbolFirst,
      html_entity: htmlEntity,
      iso_numeric: isoNumeric,
      smallest_denomination: smallestDenomination,
      ...rest
      ,
    }),
    authenticated: true,
  };
  return request(requestParams);
}
