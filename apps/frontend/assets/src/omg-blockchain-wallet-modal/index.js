import React, { useState } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'

import Modal from '../omg-modal'
import { Button, Input } from '../omg-uikit'
import { createBlockchainWallet } from '../omg-blockchain-wallet/action'

const BlockchainWalletModalStyle = styled.div`
  padding: 50px;
  display: flex;
  flex-direction: column;

  .field {
    margin-top: 40px;
  }

  .button-group {
    display: flex;
    flex-direction: row;
    margin-top: 40px;

    .button {
      flex: 1 1 0;
      &:first-child {
        margin-right: 10px;
      }
    }
  }
`

const BlockchainWalletModal = ({ createBlockchainWallet, open, onRequestClose }) => {
  const [ name, setName ] = useState('')
  const [ address, setAddress ] = useState('')
  const [ loading, setLoading ] = useState(false)

  const submit = async () => {
    setLoading(true)
    await createBlockchainWallet({
      name,
      type: 'cold',
      address
    })
    setLoading(false)
    handleClose()
  }

  const handleClose = () => {
    setName('')
    setAddress('')
    onRequestClose()
  }

  return (
    <Modal
      isOpen={open}
      onRequestClose={handleClose}
      contentLabel='create-blockchain-wallet-modal'
    >
      <BlockchainWalletModalStyle>
        <h4>Create Blockchain Wallet</h4>
        <Input
          className='field'
          placeholder='Wallet name'
          autofocus
          value={name}
          onChange={e => setName(e.target.value)}
        />
        <Input
          className='field'
          placeholder='Blockchain address'
          value={address}
          onChange={e => setAddress(e.target.value)}
        />
        <div className='button-group'>
          <Button
            className='button'
            size='small'
            type='submit'
            loading={loading}
            disabled={!name || !address}
            onClick={submit}
          >
            <span>Create</span>
          </Button>
          <Button
            className='button'
            size='small'
            type='submit'
            styleType='secondary'
            onClick={handleClose}
          >
            <span>Cancel</span>
          </Button>
        </div>
      </BlockchainWalletModalStyle>
    </Modal>
  )
}

BlockchainWalletModal.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func,
  createBlockchainWallet: PropTypes.func
}

export default connect(
  null,
  { createBlockchainWallet }
)(BlockchainWalletModal)
