import React from 'react'
import PropTypes from 'prop-types'

import Modal from '../omg-modal'

import CreateExchangeModal from './createExchangeModal'
import DeleteExchangeModal from './deleteExchangeModal'

const ExchangeRateModal = ({
  action,
  open,
  onRequestClose,
  ...restProps
}) => {
  return (
    <Modal
      isOpen={open}
      onRequestClose={onRequestClose}
      contentLabel={`${action}-exchange-rate-modal`}
    >
      {action === 'create'
        ? <CreateExchangeModal onRequestClose={onRequestClose} {...restProps} />
        : <DeleteExchangeModal onRequestClose={onRequestClose} {...restProps} />}
    </Modal>
  )
}

ExchangeRateModal.propTypes = {
  action: PropTypes.oneOf(['create', 'delete']).isRequired,
  open: PropTypes.bool,
  onRequestClose: PropTypes.func
}

export default ExchangeRateModal
