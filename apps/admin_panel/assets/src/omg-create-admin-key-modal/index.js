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
import AccountSelectRow from './AccountSelectRow'
const CreateAdminKeyModalContainer = styled.div`
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
const CreateAdminKeyButton = styled(Button)`
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
  margin-bottom: 35px;
`
const StyledSelect = styled(Select)`
  margin-bottom: 35px;
  text-align: left;
`
const InputLabel = styled.div`
  text-align: left;
  margin-bottom: 5px;
`
const enhance = compose(
  withRouter,
  connect(
    null,
    { createAccessKey }
  )
)

CreateAdminKeyModal.propTypes = {
  open: PropTypes.bool,
  createAccessKey: PropTypes.func,
  onRequestClose: PropTypes.func,
  onSubmitSuccess: PropTypes.func
}

function CreateAdminKeyModal (props) {
  const [label, setLabel] = useState('')
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  const [role, setRole] = useState('none')
  const [account, setAccountInput] = useState('')
  function onRequestClose () {
    setLabel('')
    setAccountInput('')
    setRole('none')
    setSubmitStatus('DEFAULT')
    props.onRequestClose()
  }
  function onSelectAccount (account) {
    setAccountInput(account)
  }
  function onSelectRole (role) {
    setRole(role)
  }
  async function onSubmit (e) {
    e.preventDefault()
    setSubmitStatus('SUBMITTED')
    const { data } = await props.createAccessKey({ name: label, globalRole: role })
    if (data) {
      setSubmitStatus('SUCCESS')
      props.onSubmitSuccess(data)
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
      <CreateAdminKeyModalContainer onSubmit={onSubmit}>
        <Icon name='Close' onClick={onRequestClose} />
        <CreateAdminKeyFormContainer>
          <h4>Create Admin Key</h4>
          <InputLabel>Label</InputLabel>
          <StyledInput
            autoFocus
            normalPlaceholder='Label ( optional )'
            onChange={e => setLabel(e.target.value)}
            value={label}
          />
          <InputLabel>Assign Account</InputLabel>
          <AccountsFetcher
            query={{
              perPage: 10,
              search: account
            }}
            render={({ data: accounts }) => {
              return (
                <StyledSelect
                  normalPlaceholder='Account ( optional )'
                  onChange={e => setAccountInput(e.target.value)}
                  value={account}
                  onSelectItem={item => onSelectAccount(item.key)}
                  options={accounts.map(account => ({
                    key: account.id,
                    value: <AccountSelectRow account={account} />
                  }))}
                />
              )
            }}
          />
          <InputLabel>Role</InputLabel>
          <StyledSelect
            normalPlaceholder='Role ( optional )'
            onChange={e => setRole(e.target.value)}
            value={role}
            onSelectItem={item => onSelectRole(item.key)}
            options={[
              { key: 'viewer', value: 'Viewer' },
              { key: 'admin', value: 'Admin' },
              { key: 'super_admin', value: 'Super Admin' },
              { key: 'none', value: 'none' }
            ]}
          />
          <CreateAdminKeyButton
            styleType='primary'
            type='submit'
            loading={submitStatus === 'SUBMITTED'}
          >
            Create key
          </CreateAdminKeyButton>
        </CreateAdminKeyFormContainer>
      </CreateAdminKeyModalContainer>
    </Modal>
  )
}

export default enhance(CreateAdminKeyModal)
