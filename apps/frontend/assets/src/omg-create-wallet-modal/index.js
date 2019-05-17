import React, { useState } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'

import Modal from '../omg-modal'
import { Button, Select, Input } from '../omg-uikit'
import { createWallet } from '../omg-wallet/action'

const CreateWalletModalStyle = styled.div`
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

const CreateWalletModal = ({ createWallet, accountId, isOpen, onRequestClose, onCreateWallet }) => {
  const [ name, setName ] = useState('')
  const [ identifier, setIdentifier ] = useState({
    key: 'secondary',
    value: 'secondary'
  })
  const [ loading, setLoading ] = useState(false)

  const submit = async () => {
    setLoading(true)
    await createWallet({
      name,
      identifier: identifier.value,
      accountId
    })
    onCreateWallet()
    setLoading(false)
    handleClose()
  }

  const handleClose = () => {
    setName('')
    setIdentifier({ key: 'secondary', value: 'secondary' })
    onRequestClose()
  }

  return (
    <Modal
      isOpen={isOpen}
      onRequestClose={handleClose}
      contentLabel='create-wallet-modal'
    >
      <CreateWalletModalStyle>
        <h4>Create Account Wallet</h4>
        <Input
          className='field'
          placeholder='Wallet name'
          autofocus
          value={name}
          onChange={e => setName(e.target.value)}
        />
        <Select
          className='field'
          placeholder='Wallet type'
          onSelectItem={setIdentifier}
          value={identifier.value}
          options={[
            { key: 'secondary', value: 'secondary' },
            { key: 'burn', value: 'burn' }
          ]}
        />
        <div className='button-group'>
          <Button
            className='button'
            size='small'
            type='submit'
            loading={loading}
            disabled={!name}
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
      </CreateWalletModalStyle>
    </Modal>
  )
}

CreateWalletModal.propTypes = {
  isOpen: PropTypes.bool,
  accountId: PropTypes.string,
  onRequestClose: PropTypes.func,
  onCreateWallet: PropTypes.func,
  createWallet: PropTypes.func
}

export default connect(
  null,
  { createWallet }
)(CreateWalletModal)
