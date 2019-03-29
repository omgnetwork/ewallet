import * as userService from '../services/userService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const createUser = ({ username, providerUserId }) =>
  createActionCreator({
    actionName: 'USER',
    action: 'CREATE',
    service: () => userService.createUser({ username, providerUserId })
  })

export const getUsers = ({ page, perPage, cacheKey, matchAll, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'USERS',
    action: 'REQUEST',
    service: () =>
      userService.getUsers({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })

export const getUserById = id =>
  createActionCreator({
    actionName: 'USER',
    action: 'REQUEST',
    service: () => userService.getUserById(id)
  })

