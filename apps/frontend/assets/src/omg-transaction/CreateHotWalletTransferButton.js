import React from 'react'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'

import { Button, Icon } from '../omg-uikit'
import { openModal } from '../omg-modal/action'

function CreateHotWalletTransferButton (props) {
  return (
    <Button
      key='create'
      size='small'
      styleType='primary'
      onClick={() =>
        props.openModal({ id: 'hotWalletTransferModal', fromAddress: props.fromAddress })
      }
    >
      <Icon name='Transaction' />
      <span>Transfer</span>
    </Button>
  )
}

export default connect(
  null,
  { openModal }
)(CreateHotWalletTransferButton)

CreateHotWalletTransferButton.propTypes = {
  openModal: PropTypes.func.isRequired,
  fromAddress: PropTypes.string
}
