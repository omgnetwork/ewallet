import * as accountService from '../services/accountService'
import * as adminService from '../services/adminService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const inviteMember = ({ email, redirectUrl, accountId, role }) =>
  createActionCreator({
    actionName: 'INVITE',
    action: 'REQUEST',
    service: () =>
      accountService.inviteMember({
        email,
        redirectUrl: `${redirectUrl}?token={token}&email={email}`,
        accountId,
        role
      })
  })

export const getListMembers = ({ accountId, matchAll, matchAny, cacheKey }) => {
  return createPaginationActionCreator({
    actionName: 'INVITE_LIST',
    action: 'REQUEST',
    service: () =>
      accountService.listMembers({
        accountId,
        matchAll,
        matchAny
      }),
    cacheKey
  })
}

export const createUser = ({ resetToken, password, passwordConfirmation, email }) =>
  createActionCreator({
    actionName: 'INVITE',
    action: 'CREATE',
    service: () =>
      adminService.createAdmin({
        resetToken,
        password,
        passwordConfirmation,
        email
      })
  })
