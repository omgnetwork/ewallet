import React, { useState } from 'react'
import styled from 'styled-components'
import { Input, Button, Icon, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import { connect } from 'react-redux'
import AccountsFetcher from '../omg-account/accountsFetcher'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import { createAccessKey } from '../omg-access-key/action'
import PropTypes from 'prop-types'
const CreateAdminKeyModalContainer = styled.div`
  padding: 50px;
  width: 100vw;
  height: 100vh;
  text-align: left;
  position: relative;
  box-sizing: border-box;
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
const InviteButton = styled(Button)`
  padding-left: 40px;
  padding-right: 40px;
`
const CreateAdminKeyFormContainer = styled.form`
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  left: 0;
  right: 0;
  margin: 0 auto;
  width: 400px;
`
const StyledInput = styled(Input)`
  margin-bottom: 30px;
`
const StyledSelect = styled(Select)`
  margin-bottom: 30px;
`
const enhance = compose(
  withRouter,
  connect(
    null,
    { createAccessKey }
  )
)

InviteModal.propTypes = {
  open: PropTypes.func,
  createAccessKey: PropTypes.func,
  onRequestClose: PropTypes.func
}

function InviteModal (props) {
  const [label, setLabel] = useState()
  const [submitStatus, setSubmitStatus] = useState()
  const [role, setRole] = useState()
  const [account, setAccount] = useState()

  function onRequestClose () {
    props.onRequestClose()
    setLabel()
    setSubmitStatus()
  }

  function onSubmit () {
    props.createAccessKey()
  }

  return (
    <Modal
      isOpen={props.open}
      onRequestClose={onRequestClose}
      contentLabel='invite modal'
      shouldCloseOnOverlayClick={false}
      overlayClassName='dummy'
    >
      <CreateAdminKeyModalContainer onSubmit={onSubmit}>
        <Icon name='Close' onClick={onRequestClose} />
        <CreateAdminKeyFormContainer>
          <h4>Create Admin Key</h4>
          <StyledInput
            autoFocus
            placeholder='Label'
            onChange={e => setLabel(e.target.value)}
            value={label}
          />
          <AccountsFetcher
            query={{
              perPage: 10,
              search: account
            }}
            render={({ data: accounts }) => {
              return (
                <StyledSelect
                  placeholder='Account'
                  onChange={e => setAccount(e.target.value)}
                  value={account}
                  options={accounts.map(account => ({ key: account.id, value: account.id }))}
                />
              )
            }}
          />
          <StyledSelect
            placeholder='Role'
            onChange={e => setRole(e.target.value)}
            value={role}
            options={[{ key: 'aa', value: '123' }]}
          />
          <InviteButton styleType='primary' type='submit' loading={submitStatus === 'SUBMITTED'}>
            Create key
          </InviteButton>
        </CreateAdminKeyFormContainer>
      </CreateAdminKeyModalContainer>
    </Modal>
  )
}

export default enhance(InviteModal)
