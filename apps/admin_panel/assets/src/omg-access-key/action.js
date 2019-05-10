import * as accessKeyService from '../services/accessKeyService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const createAccessKey = ({ name, globalRole, accountId, roleName }) =>
  createActionCreator({
    actionName: 'ACCESS_KEY',
    action: 'CREATE',
    service: () => accessKeyService.createAccessKey({
      name,
      globalRole,
      accountId,
      roleName
    })
  })

export const deleteAccessKey = id =>
  createActionCreator({
    actionName: 'ACCESS_KEY',
    action: 'DELETE',
    service: () => accessKeyService.deleteAccessKeyById(id)
  })

export const getAccessKey = id =>
  createActionCreator({
    actionName: 'ACCESS_KEY',
    action: 'REQUEST',
    service: () => accessKeyService.getAccessKey(id)
  })

export const getAccessKeyMemberships = ({
  id,
  startAfter,
  startBy,
  perPage,
  matchAll,
  matchAny,
  sortBy,
  sortDir,
  cacheKey
}) =>
  createPaginationActionCreator({
    actionName: 'ACCESS_KEY_MEMBERSHIPS',
    action: 'REQUEST',
    service: () =>
      accessKeyService.getAccessKeyMemberships({
        id,
        startAfter,
        startBy,
        perPage,
        matchAll,
        matchAny,
        sortBy: 'created_at',
        sortDir: 'desc'
      }),
    cacheKey
  })

export const updateAccessKey = ({ id, name, globalRole }) =>
  createActionCreator({
    actionName: 'ACCESS_KEY',
    action: 'UPDATE',
    service: () => accessKeyService.updateAccessKey({ id, name, globalRole })
  })

export const enableAccessKey = ({ id, enabled }) =>
  createActionCreator({
    actionName: 'ACCESS_KEY',
    action: 'UPDATE',
    service: () => accessKeyService.enableAccessKey({ id, enabled })
  })

export const getAccessKeys = ({ page, perPage, matchAll, matchAny, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'ACCESS_KEYS',
    action: 'REQUEST',
    service: () =>
      accessKeyService.getAccessKeys({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })

export const downloadKey = ({ accessKey, secretKey }) => disatch => {
  const rows = [['access_key', 'secret_key'], [accessKey, secretKey]]
  const csvContent = 'data:text/csv;charset=utf-8,' + rows.map(e => e.join(',')).join('\n')
  const encodedUri = encodeURI(csvContent)
  const link = document.createElement('a')
  link.setAttribute('href', encodedUri)
  link.setAttribute('download', `key-${accessKey}.csv`)
  document.body.appendChild(link)
  link.click()
}
