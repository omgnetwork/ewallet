import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import * as exportActions from './action'
import * as exportService from '../services/exportService'

jest.mock('../services/exportService.js')
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)

let store
describe('export actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
    global.window = Object.create(window)
    Object.defineProperty(window, 'location', {
      value: {
        href: 'http://example.org/'
      }
    })
    Object.defineProperty(window, 'URL', {
      value: {
        createObjectURL: jest.fn()
      }
    })
  })

  test('[downloadExportFileById] with AWS storage type should dispatch success action with correct params if get export successfully', () => {
    const awsFile = {
      id: 'id',
      adapter: 'aws'
    }
    exportService.getExportFileById.mockImplementation(() => {
      return Promise.resolve({
        data: { success: true, data: { id: 'id', download_url: 'url', adapter: 'aws' } }
      })
    })
    const expectedActions = [
      { type: 'EXPORT/DOWNLOAD/INITIATED' },
      {
        type: 'EXPORT/DOWNLOAD/SUCCESS',
        data: { success: true, data: { id: 'id', download_url: 'url', adapter: 'aws' } }
      }
    ]
    return store.dispatch(exportActions.downloadExportFileById(awsFile)).then(() => {
      expect(exportService.getExportFileById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[downloadExportFileById] with GCS storage type should dispatch success action with correct params if get export successfully', () => {
    const gcsFile = {
      id: 'id',
      adapter: 'gcs'
    }
    exportService.getExportFileById.mockImplementation(() => {
      return Promise.resolve({
        data: { success: true, data: { id: 'id', download_url: 'url', adapter: 'gcs' } }
      })
    })
    const expectedActions = [
      { type: 'EXPORT/DOWNLOAD/INITIATED' },
      {
        type: 'EXPORT/DOWNLOAD/SUCCESS',
        data: { success: true, data: { id: 'id', download_url: 'url', adapter: 'gcs' } }
      }
    ]
    return store.dispatch(exportActions.downloadExportFileById(gcsFile)).then(() => {
      expect(exportService.getExportFileById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[downloadExportFileById] with LOCAL storage type should dispatch success action with correct params if get export successfully', () => {
    const localFile = {
      id: 'id',
      adapter: 'local'
    }
    exportService.downloadExportFileById.mockImplementation(() => {
      return Promise.resolve({
        data: { success: true, data: { ...localFile, download_url: null } }
      })
    })
    const expectedActions = [
      { type: 'EXPORT/DOWNLOAD/INITIATED' },
      {
        type: 'EXPORT/DOWNLOAD/SUCCESS',
        data: { success: true, data: { id: 'id', download_url: null, adapter: 'local' } }
      }
    ]
    return store.dispatch(exportActions.downloadExportFileById(localFile)).then(() => {
      expect(exportService.downloadExportFileById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
