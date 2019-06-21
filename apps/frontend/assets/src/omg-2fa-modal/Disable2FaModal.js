import React, { useState } from 'react'
import { useDispatch } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'

import Modal from '../omg-modal'
import { disable2Fa } from '../omg-2fa/action'
import { Input, Button, Icon } from '../omg-uikit'

const Disable2FaModalContainer = styled.div`
  padding: 50px;
  text-align: center;
  width: 450px;
  position: relative;
  i {
    position: absolute;
    top: 15px;
    right: 15px;
    cursor: pointer;
  }

  input {
    text-align: center;
    font-size: 18px;
  }

  button {
    margin-top: 30px;
  }
  h4 {
    margin-bottom: 10px;
  }
  .backup-container {
    text-align: center;
    p {
      margin: 20px 0;
    }
  }
  .backup-item {
    padding: 5px;
    display: inline-block;
    width: 110px;
  }
`

function DisableTwoFaModal ({ open, onRequestClose, history }) {
  const dispatch = useDispatch()
  const [passcode, setPasscode] = useState('')
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  const afterClose = () => {
    setPasscode('')
    setSubmitStatus('DEFAULT')
  }

  const onSubmit = async e => {
    e.preventDefault()
    setSubmitStatus('LOADING')
    const result = await disable2Fa(passcode)(dispatch)
    if (result.data) {
      setSubmitStatus('SUCCESS')
      onRequestClose()
      history.push('/login')
    } else {
      setSubmitStatus('FAILED')
    }
  }

  const renderDisableSection = () => {
    return (
      <form onSubmit={onSubmit}>
        <h4>Disable Two Factor Authentication</h4>
        <Input
          value={passcode}
          onChange={e => setPasscode(e.target.value)}
          normalPlaceholder='2fa token...'
          autoFocus
          maxLength={6}
        />
        <Button loading={submitStatus === 'LOADING'}>
          Disable Two Factor Authentication<br />
          ( This Will Log You Out )
        </Button>
      </form>
    )
  }

  return (
    <Modal
      isOpen={open}
      onRequestClose={onRequestClose}
      onAfterClose={afterClose}
    >
      <Disable2FaModalContainer>
        <Icon name='Close' onClick={onRequestClose} />
        {renderDisableSection()}
      </Disable2FaModalContainer>
    </Modal>
  )
}

DisableTwoFaModal.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func,
  history: PropTypes.object
}
export default withRouter(DisableTwoFaModal)
