import * as userService from '../services/userService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const createUser = ({ username, providerUserId }) =>
  createActionCreator({
    actionName: 'USER',
    action: 'CREATE',
    service: () => userService.createUser({ username, providerUserId })
  })

export const getUsers = ({ accountId, search, page, perPage, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'USERS',
    action: 'REQUEST',
    service: () =>
      userService.getUsers({
        accountId,
        perPage: perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search
      }),
    cacheKey
  })

export const getUserById = id =>
  createActionCreator({
    actionName: 'USER',
    action: 'REQUEST',
    service: () => userService.getUserById(id)
  })
