import React from 'react'
import { Button, Icon } from '../omg-uikit'
import { connect } from 'react-redux'
import { openModal } from '../omg-modal/action'
import PropTypes from 'prop-types'
function CreateTransactionButton (props) {
  return (
    <Button
      key='create'
      size='small'
      styleType='primary'
      onClick={() =>
        props.openModal({ id: 'createTransaction', fromAddress: props.fromAddress })
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
)(CreateTransactionButton)

CreateTransactionButton.propTypes = {
  openModal: PropTypes.func.isRequired,
  fromAddress: PropTypes.string
}
