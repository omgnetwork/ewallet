import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getListMembers, inviteMember } from './action'
import * as accountService from '../services/accountService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/accountService')
let store
describe('invite actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[getListMembers] should dispatch success action if successfully invite member', () => {
    accountService.inviteMember.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' }, success: true } })
    })
    const expectedActions = [
      { type: 'INVITE/REQUEST/INITIATED' },
      { type: 'INVITE/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store
      .dispatch(
        inviteMember({
          email: 'xxx@gmail.com',
          redirectUrl: 'url',
          accountId: '1234',
          role: 'admin'
        })
      )
      .then(() => {
        expect(accountService.inviteMember).toBeCalledWith({
          email: 'xxx@gmail.com',
          redirectUrl: 'url?token={token}&email={email}',
          accountId: '1234',
          role: 'admin'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
  test('[inviteMember] should dispatch failed action if failed to invite member', () => {
    accountService.inviteMember.mockImplementation(() => {
      return Promise.resolve({ data: { data: 'eth1000usd', success: false } })
    })
    const expectedActions = [
      { type: 'INVITE/REQUEST/INITIATED' },
      { type: 'INVITE/REQUEST/FAILED', error: 'eth1000usd' }
    ]
    return store
      .dispatch(
        inviteMember({
          email: 'xxx@gmail.com',
          redirectUrl: 'url',
          accountId: '1234',
          role: 'admin'
        })
      )
      .then(() => {
        expect(accountService.inviteMember).toBeCalledWith({
          email: 'xxx@gmail.com',
          redirectUrl: 'url?token={token}&email={email}',
          accountId: '1234',
          role: 'admin'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[getListMembers] should dispatch success action if successfully invite member', () => {
    accountService.listMembers.mockImplementation(() => {
      return Promise.resolve({ data: { data: { data: 'a' }, success: true } })
    })
    const expectedActions = [
      { type: 'INVITE_LIST/REQUEST/INITIATED' },
      { type: 'INVITE_LIST/REQUEST/SUCCESS', data: 'a', pagination: undefined, cacheKey: 'key' }
    ]
    return store
      .dispatch(
        getListMembers({
          page: 1,
          perPage: 10,
          cacheKey: 'key',
          accountId: 'a',
          matchAll: [],
          matchAny: []
        })
      )
      .then(() => {
        expect(accountService.listMembers).toBeCalledWith(
          expect.objectContaining({
            page: 1,
            perPage: 10,
            accountId: 'a',
            matchAll: [],
            matchAny: []
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[getListMembers] should dispatch failed action if failed to invite member', () => {
    accountService.listMembers.mockImplementation(() => {
      return Promise.resolve({ data: { data: 'eth1000usd', success: false } })
    })
    const expectedActions = [
      { type: 'INVITE_LIST/REQUEST/INITIATED' },
      { type: 'INVITE_LIST/REQUEST/FAILED', error: 'eth1000usd' }
    ]
    return store
      .dispatch(getListMembers({ page: 1, perPage: 10, cacheKey: 'key', accountId: 'a' }))
      .then(() => {
        expect(accountService.listMembers).toBeCalledWith(
          expect.objectContaining({
            page: 1,
            perPage: 10,
            accountId: 'a'
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
})
