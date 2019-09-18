import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import FullpageModal from '../omg-modal/FullpageModal'

const BlockchainDepositContainer = styled.div`
  width: 100vw;
  height: 100vh;
  position: relative;
  i[name='Close'] {
    position: absolute;
    right: 20px;
    top: 20px;
  }
`
const MetaMaskImage = styled.img`
  max-width: 250px;
`
function BlockchainDeposit () {
  return (
    <BlockchainDepositContainer>
      <div>
        <MetaMaskImage src={require('../../statics/images/metamask.svg')} />
        METAMASK
      </div>
      <div>LEDGER</div>
    </BlockchainDepositContainer>
  )
}

function BlockchainDepositModalContainer ({ open, onRequestClose }) {
  return (
    <FullpageModal
      isOpen={open}
      onRequestClose={onRequestClose}
      contentLabel='blockchain deposit modal'
      overlayClassName='blockchain-deposit-modal'
    >
      <BlockchainDeposit />
    </FullpageModal>
  )
}

BlockchainDepositModalContainer.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func
}

export default BlockchainDepositModalContainer
