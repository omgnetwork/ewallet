import * as configurationService from '../services/configurationService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const updateConfiguration = config =>
  createActionCreator({
    actionName: 'CONFIGURATION',
    action: 'UPDATE',
    service: () => configurationService.updateConfiguration(config)
  })

export const getConfiguration = ({ page, perPage, matchAll, matcHAny, cacheKey }) => {
  return createPaginationActionCreator({
    actionName: 'CONFIGURATIONS',
    action: 'REQUEST',
    service: () =>
      configurationService.getConfiguration({
        page,
        perPage,
        matchAll,
        matcHAny,
        sort: {
          dir: 'desc',
          by: 'position'
        }
      }),
    cacheKey
  })
}
