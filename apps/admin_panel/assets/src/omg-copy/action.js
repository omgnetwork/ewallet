import copy from 'copy-to-clipboard'

export const copyToClipboard = data => dispatch => {
  copy(data)
  dispatch({ type: 'CLIPBOARD/COPY/SUCCESS', data })
}
