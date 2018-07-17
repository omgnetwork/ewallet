import * as accessKeyService from '../services/accessKeyService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'
export const createAccessKey = owner =>
  createActionCreator({
    actionName: 'ACCESS_KEY',
    action: 'CREATE',
    service: accessKeyService.createAccessKey
  })
export const deleteAccessKey = id =>
  createActionCreator({
    actionName: 'ACCESS_KEY',
    action: 'DELETE',
    service: () => accessKeyService.deleteAccessKeyById(id)
  })
export const updateAccessKey = ({ id, expired }) =>
  createActionCreator({
    actionName: 'ACCESS_KEY',
    action: 'UPDATE',
    service: () => accessKeyService.updateAccessKey({ id, expired })
  })

export const getAccessKeys = ({ page, perPage, search, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'ACCESS_KEYS',
    action: 'REQUEST',
    service: () =>
      accessKeyService.getAccessKeys({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search
      }),
    cacheKey
  })
