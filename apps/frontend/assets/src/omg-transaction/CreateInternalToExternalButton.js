import React from 'react'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'

import { Button, Icon } from '../omg-uikit'
import { openModal } from '../omg-modal/action'

function CreateInternalToExternalButton (props) {
  return (
    <Button
      key='create'
      size='small'
      styleType='primary'
      onClick={() =>
        props.openModal({ id: 'internalToExternalModal', wallet: props.wallet })
      }
    >
      <Icon name='Transaction' />
      <span>External Transfer</span>
    </Button>
  )
}

export default connect(
  null,
  { openModal }
)(CreateInternalToExternalButton)

CreateInternalToExternalButton.propTypes = {
  openModal: PropTypes.func.isRequired,
  wallet: PropTypes.object
}
