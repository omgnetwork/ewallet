import * as configurationService from '../services/configurationService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const updateConfiguration = config =>
  createActionCreator({
    actionName: 'CONFIGURATIONS',
    action: 'UPDATE',
    service: () => configurationService.updateConfiguration(config)
  })

export const getConfiguration = () => {
  return createActionCreator({
    actionName: 'CONFIGURATIONS',
    action: 'REQUEST',
    service: () =>
      configurationService.getConfiguration()
  })
}
