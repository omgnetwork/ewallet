import React, { useState } from 'react'
import { useDispatch } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import _ from 'lodash'

import Modal from '../omg-modal'
import { login2Fa } from '../omg-2fa/action'
import { Input, Button, Icon } from '../omg-uikit'

const Enter2FaModalContainer = styled.div`
  padding: 40px;
  text-align: center;
  width: 400px;
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

function Enter2FaModal ({ open, onRequestClose, history, location }) {
  const dispatch = useDispatch()
  const [passcode, setPasscode] = useState('')
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  const [errorText, setErrorText] = useState()
  const afterClose = () => {
    setPasscode('')
    setSubmitStatus('DEFAULT')
  }

  const onSubmit = async e => {
    e.preventDefault()
    setSubmitStatus('LOADING')
    const result = await login2Fa(passcode)(dispatch)
    if (result.data) {
      setSubmitStatus('SUCCESS')
      history.push(_.get(location, 'state.from', '/'))
      onRequestClose()
    } else {
      setErrorText(result.error.description)
      setSubmitStatus('FAILED')
    }
  }

  const renderDisableSection = () => {
    return (
      <form onSubmit={onSubmit}>
        <h4>Your Two Factor Authentication Code</h4>
        <Input
          value={passcode}
          onChange={e => setPasscode(e.target.value)}
          normalPlaceholder='2fa token...'
          error={submitStatus === 'FAILED'}
          errorText={errorText}
          autoFocus
        />
        <Button loading={submitStatus === 'LOADING'}>Submit</Button>
      </form>
    )
  }

  return (
    <Modal
      isOpen={open}
      onRequestClose={onRequestClose}
      onAfterClose={afterClose}
    >
      <Enter2FaModalContainer>
        <Icon name='Close' onClick={onRequestClose} />
        {renderDisableSection()}
      </Enter2FaModalContainer>
    </Modal>
  )
}

Enter2FaModal.propTypes = {
  open: PropTypes.bool,
  onRequestClose: PropTypes.func,
  history: PropTypes.object,
  location: PropTypes.object
}
export default withRouter(Enter2FaModal)
