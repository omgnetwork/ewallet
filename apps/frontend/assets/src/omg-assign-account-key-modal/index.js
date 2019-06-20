import React, { useState } from 'react'
import styled from 'styled-components'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

import Modal from '../omg-modal'
import { Button, Icon, Select } from '../omg-uikit'
import { assignKey } from '../omg-account/action'
import AccountsFetcher from '../omg-account/accountsFetcher'
import AccountSelectRow from '../omg-create-admin-key-modal/AccountSelectRow'

const AssignAccountToKeyContainer = styled.div`
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
  h3 {
    margin-bottom: 35px;
    text-align: left;
  }
  button {
    display: block;
    margin-top: 35px;
  }
`
const FormContainer = styled.form`
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  left: 0;
  right: 0;
  margin: 0 auto;
  width: 400px;
`
const StyledSelect = styled(Select)`
  margin-bottom: 35px;
  text-align: left;
  padding-top: 10px;
`
const InputLabel = styled.div`
  text-align: left;
  margin-bottom: 5px;
`

function AssignAccountToKey (props) {
  const [submitStatus, setSubmitStatus] = useState('DEFAULT')
  const [role, setRole] = useState('viewer')

  const [accountId, setAccountId] = useState('')

  function onRequestClose () {
    setAccountId('')
    props.onRequestClose()
  }

  function onSelectAccount (account) {
    setAccountId(account.key)
  }

  async function onSubmit (e) {
    e.preventDefault()
    setSubmitStatus('SUBMITTED')
    const { data } = await props.assignKey({ keyId: props.keyId, accountId, role })
    if (data) {
      setSubmitStatus('SUCCESS')
      props.onSubmitSuccess()
      onRequestClose()
    } else {
      setSubmitStatus('FAILED')
    }
  }

  function renderAssignKey () {
    return (
      <AssignAccountToKeyContainer onSubmit={onSubmit}>
        <Icon name='Close' onClick={onRequestClose} />
        <FormContainer>
          <h3>Assign Account</h3>

          <InputLabel>Assign Account</InputLabel>
          <AccountsFetcher
            render={({ data: accounts }) => {
              return (
                <StyledSelect
                  normalPlaceholder='Add Account ID'
                  value={accountId}
                  noBorder={!!accountId}
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

          <InputLabel>Account Role</InputLabel>
          <StyledSelect
            normalPlaceholder={'Account\'s Role'}
            value={_.startCase(role)}
            onSelectItem={item => setRole(item.key)}
            options={[
              { key: 'admin', value: 'Admin' },
              { key: 'viewer', value: 'Viewer' }
            ]}
          />

          <Button
            styleType='primary'
            type='submit'
            loading={submitStatus === 'SUBMITTED'}
          >
            <span>Assign Account</span>
          </Button>

        </FormContainer>
      </AssignAccountToKeyContainer>
    )
  }

  return (
    <Modal
      isOpen={props.open}
      onRequestClose={onRequestClose}
      contentLabel='assign-key-modal'
      overlayClassName='dummy'
      shouldCloseOnOverlayClick
    >
      {renderAssignKey()}
    </Modal>
  )
}

const enhance = compose(
  withRouter,
  connect(
    null,
    { assignKey }
  )
)

AssignAccountToKey.propTypes = {
  open: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  onSubmitSuccess: PropTypes.func,
  assignKey: PropTypes.func,
  keyId: PropTypes.string.isRequired
}
AssignAccountToKey.defaultProps = {
  onSubmitSuccess: _.noop
}

export default enhance(AssignAccountToKey)
