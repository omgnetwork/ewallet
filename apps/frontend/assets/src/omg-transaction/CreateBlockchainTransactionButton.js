import React from 'react'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'
import { Button } from '../omg-uikit'
import { openModal } from '../omg-modal/action'

function CreateBlockchainTransactionButton (props) {
  return (
    <Button
      key='create'
      size='small'
      styleType='primary'
      onClick={() =>
        props.openModal({ id: 'createBlockchainTransaction', fromAddress: props.fromAddress })
      }
      disabled={!window.web3 || !window.ethereum}
    >
      <span>Topup</span>
    </Button>
  )
}

export default connect(
  null,
  { openModal }
)(CreateBlockchainTransactionButton)

CreateBlockchainTransactionButton.propTypes = {
  openModal: PropTypes.func.isRequired,
  fromAddress: PropTypes.string
}
