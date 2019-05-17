import React, { useState } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'

import { Input, Button, Icon } from '../omg-uikit'
import Modal from '../omg-modal'
import { createApiKey } from '../omg-api-keys/action'

const CreateClientKeyModalContainer = styled.div`
  padding: 50px;
  width: 100vw;
  height: 100vh;
  position: relative;
  box-sizing: border-box;
  text-align: center;
  > i {
    position: absolute;
    right: 30px;
    top: 30px;
    font-size: 30px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  h4 {
    margin-bottom: 35px;
    text-align: center;
  }
  > button {
    margin-top: 35px;
  }
`

const CreateClientKeyFormContainer = styled.form`
  position: absolute;
  top: 50%;

  transform: translateY(-50%);
  left: 0;
  right: 0;
  margin: 0 auto;
  width: 400px;

  h3 {
    text-align: left;
    margin-bottom: 35px;
  }

  button {
    display: block;
  }
`
const StyledInput = styled(Input)`
  margin-bottom: 30px;
`
const InputLabel = styled.div`
  text-align: left;
  margin-bottom: 5px;
`
const enhance = compose(
  withRouter,
  connect(
    null,
    { createApiKey }
  )
)

CreateClientKeyModal.propTypes = {
  open: PropTypes.bool,
  createApiKey: PropTypes.func,
  onRequestClose: PropTypes.func,
  onSubmitSuccess: PropTypes.func
}

function CreateClientKeyModal (props) {
  const [name, setName] = useState('')
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  function onRequestClose () {
    setName('')
    setSubmitStatus('DEFAULT')
    props.onRequestClose()
  }
  async function onSubmit (e) {
    e.preventDefault()
    setSubmitStatus('SUBMITTED')
    const { data } = await props.createApiKey({ name })
    if (data) {
      setSubmitStatus('SUCCESS')
      props.onSubmitSuccess()
      onRequestClose()
    }
  }

  return (
    <Modal
      isOpen={props.open}
      onRequestClose={onRequestClose}
      contentLabel='invite modal'
      shouldCloseOnOverlayClick={false}
      overlayClassName='dummy'
    >
      <CreateClientKeyModalContainer onSubmit={onSubmit}>
        <Icon name='Close' onClick={onRequestClose} />
        <CreateClientKeyFormContainer>
          <h3>Generate Client Key</h3>
          <InputLabel>Label</InputLabel>
          <StyledInput
            autoFocus
            normalPlaceholder='Label (Optional)'
            onChange={e => setName(e.target.value)}
            value={name}
          />
          <Button
            styleType='primary'
            type='submit'
            loading={submitStatus === 'SUBMITTED'}
          >
            <span>Generate Key</span>
          </Button>
        </CreateClientKeyFormContainer>
      </CreateClientKeyModalContainer>
    </Modal>
  )
}

export default enhance(CreateClientKeyModal)
