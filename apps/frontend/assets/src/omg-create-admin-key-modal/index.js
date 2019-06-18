import React, { useState } from 'react'
import styled from 'styled-components'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

import Modal from '../omg-modal'
import { Input, Button, Icon, Select } from '../omg-uikit'
import { createAccessKey } from '../omg-access-key/action'
import { assignKey } from '../omg-account/action.js'
import AccountsFetcher from '../omg-account/accountsFetcher'
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
const CreateAdminKeyFormContainer = styled.form`
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

function CreateAdminKeyModal (props) {
  const [label, setLabel] = useState('')
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  const [role, setRole] = useState('none')
  const [roleName, setRoleName] = useState('viewer')
  const [accountId, setAccountId] = useState(props.accountId)

  function onRequestClose () {
    setLabel('')
    setSubmitStatus('DEFAULT')
    setRole('none')
    props.onRequestClose()
  }

  function onSelectRole (role) {
    setRole(role)
  }

  function onSelectAccount (item) {
    setAccountId(item.key)
  }

  async function onSubmit (e) {
    e.preventDefault()
    setSubmitStatus('SUBMITTED')
    const { data } = await props.createAccessKey({
      name: label,
      globalRole: role,
      accountId,
      roleName
    })
    if (data) {
      setSubmitStatus('SUCCESS')
      props.onSubmitSuccess(data)
      onRequestClose()
    } else {
      setSubmitStatus('FAILED')
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
          <h3>Generate Admin Key</h3>

          <InputLabel>Label</InputLabel>
          <StyledInput
            autoFocus
            normalPlaceholder='Enter Label'
            onChange={e => setLabel(e.target.value)}
            value={label}
          />

          {!props.hideAccount && (
            <>
              <InputLabel>Assign Account</InputLabel>
              <AccountsFetcher
                render={({ data: accounts }) => {
                  return (
                    <StyledSelect
                      disabled={!!props.accountId}
                      normalPlaceholder='Add Account ID'
                      value={accountId}
                      noBorder={!!accountId}
                      style={{ paddingTop: '10px' }}
                      valueRenderer={value => {
                        const account = _.find(accounts, account => account.id === value)
                        return <AccountSelectRow withCopy account={account} />
                      }}
                      onSelectItem={onSelectAccount}
                      options={accounts
                        .filter(account => account.id !== accountId)
                        .map(account => {
                          return {
                            key: account.id,
                            value: <AccountSelectRow key={account.id} account={account} />
                          }
                        })}
                    />
                  )
                }}
              />
            </>
          )}

          {!accountId && (
            <>
              <InputLabel>Assign Role</InputLabel>
              <StyledSelect
                normalPlaceholder='Role ( optional )'
                value={_.startCase(role)}
                onSelectItem={item => onSelectRole(item.key)}
                options={[
                  { key: 'super_admin', value: 'Super Admin' },
                  { key: 'admin', value: 'Admin' },
                  { key: 'viewer', value: 'Viewer' },
                  { key: 'none', value: 'None' }
                ]}
                optionRenderer={value => _.startCase(value)}
              />
            </>
          )}

          {accountId && (
            <>
              <InputLabel>Assign Role</InputLabel>
              <StyledSelect
                normalPlaceholder='Add Role'
                value={_.startCase(roleName)}
                onSelectItem={item => setRoleName(item.key)}
                options={[
                  { key: 'admin', value: 'Admin' },
                  { key: 'viewer', value: 'Viewer' }
                ]}
                optionRenderer={value => _.startCase(value)}
              />
            </>
          )}

          <Button
            styleType='primary'
            type='submit'
            loading={submitStatus === 'SUBMITTED'}
          >
            <span>Generate Key</span>
          </Button>
        </CreateAdminKeyFormContainer>
      </CreateAdminKeyModalContainer>
    </Modal>
  )
}

const enhance = compose(
  withRouter,
  connect(
    null,
    { createAccessKey, assignKey }
  )
)

CreateAdminKeyModal.propTypes = {
  open: PropTypes.bool,
  createAccessKey: PropTypes.func,
  onRequestClose: PropTypes.func,
  onSubmitSuccess: PropTypes.func,
  accountId: PropTypes.string,
  hideAccount: PropTypes.bool
}

export default enhance(CreateAdminKeyModal)
