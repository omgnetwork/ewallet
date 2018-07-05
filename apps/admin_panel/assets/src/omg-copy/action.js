import copy from 'copy-to-clipboard'

export const copyToClipboard = data => dispatch => {
  copy(data)
  dispatch({ type: 'COPY_TO_CLIPBAORD', data })
}
