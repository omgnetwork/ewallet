import * as configurationService from '../services/configurationService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const updateConfiguration = config =>
  createActionCreator({
    actionName: 'CONFIGURATION',
    action: 'UPDATE',
    service: () => configurationService.updateConfiguration(config)
  })

export const getConfiguration = ({ page, perPage, matchAll, matcHAny }) =>
  createActionCreator({
    actionName: 'CONFIGURATION',
    action: 'REQUEST',
    service: () => configurationService.createPaginationActionCreator({ page, perPage, matchAll, matcHAny })
  })
