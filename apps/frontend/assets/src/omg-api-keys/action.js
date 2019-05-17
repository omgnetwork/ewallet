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
export const updateApiKey = ({ id, name }) =>
  createActionCreator({
    actionName: 'API_KEY',
    action: 'UPDATE',
    service: () => apikeyService.updateApiKey({ id, name })
  })
export const enableApiKey = ({ id, enabled }) =>
  createActionCreator({
    actionName: 'API_KEY',
    action: 'UPDATE',
    service: () => apikeyService.enableApiKey({ id, enabled })
  })
export const getApiKey = id =>
  createActionCreator({
    actionName: 'API_KEY',
    action: 'REQUEST',
    service: () => apikeyService.getApiKey(id)
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
