import * as apikeyService from '../services/apikeyService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'
export const createApiKey = ({ name }) =>
  createActionCreator({
    actionName: 'API_KEY',
    action: 'CREATE',
    service: () => apikeyService.createApikey({ name })
  })
export const deleteApiKey = id =>
  createActionCreator({
    actionName: 'API_KEY',
    action: 'DELETE',
    service: () => apikeyService.deleteApiKeyById(id)
  })
export const updateApiKey = ({ id, expired }) =>
  createActionCreator({
    actionName: 'API_KEY',
    action: 'UPDATE',
    service: () => apikeyService.updateApiKey({ id, expired })
  })

export const getApiKeys = ({ page, perPage, matchAll, matchAny, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'API_KEYS',
    action: 'REQUEST',
    service: () =>
      apikeyService.getAllApikey({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })
