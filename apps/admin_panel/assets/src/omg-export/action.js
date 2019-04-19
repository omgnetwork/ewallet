import * as exportService from '../services/exportService'
import CONSTANT from '../constants'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const getExport = id => {
  return createActionCreator({
    actionName: 'EXPORT',
    action: 'REQUEST',
    service: () => exportService.getExportFileById(id)
  })
}

export const getExports = ({ page, perPage, matchAll, matchAny, cacheKey }) => {
  return createPaginationActionCreator({
    actionName: 'EXPORTS',
    action: 'REQUEST',
    service: () =>
      exportService.getExportFiles({
        page,
        perPage,
        matchAll,
        matchAny,
        sortBy: 'created_at',
        sortDir: 'desc'
      }),
    cacheKey
  })
}

export const downloadExportFileById = file => async dispatch => {
  const dispatchError = error => {
    console.error('failed to dispatch action EXPORT/DOWNLOAD', 'with error', error)
    return dispatch({
      type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.FAILED}`,
      error: error
    })
  }

  const downloadWithUrl = async fileId => {
    const result = await exportService.getExportFileById(fileId)
    if (result.data.success) {
      window.location.href = result.data.data.download_url
      return dispatch({
        type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.SUCCESS}`,
        data: result.data
      })
    } else {
      return dispatch({
        type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.FAILED}`,
        error: `Failed to fetch file ${file.id}`
      })
    }
  }

  try {
    dispatch({
      type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.INITIATED}`
    })
    switch (file.adapter) {
      case 'local':
        const result = await exportService.downloadExportFileById(file.id)
        if (result.data) {
          createBlobDownloadCsvLink(result.data, file.filename)
          return dispatch({
            type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.SUCCESS}`,
            data: result.data
          })
        } else {
          return dispatch({
            type: `EXPORT/DOWNLOAD/${CONSTANT.LOADING_STATUS.FAILED}`,
            error: result.data
          })
        }
      case 'gcs':
        return downloadWithUrl(file.id)
      case 'aws':
        return downloadWithUrl(file.id)
    }
  } catch (error) {
    dispatchError(error)
  }
}

export const createBlobDownloadCsvLink = (data, filename) => {
  const csvData = new window.Blob([data], { type: 'text/csv;charset=utf-8;' })
  const csvURL = window.URL.createObjectURL(csvData)
  const tempLink = document.createElement('a')
  tempLink.href = csvURL
  tempLink.setAttribute('download', `${filename}.csv`)
  tempLink.click()
}
