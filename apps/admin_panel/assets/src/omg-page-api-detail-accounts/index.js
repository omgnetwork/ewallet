import React, { useState } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Link } from 'react-router-dom'
import queryString from 'query-string'
import moment from 'moment'

import SortableTable from '../omg-table'
import Modal from '../omg-modal'
import { Avatar, Button, Breadcrumb, Icon, Id, Select } from '../omg-uikit'
import TopNavigation from '../omg-page-layout/TopNavigation'
import AccessKeyMembershipsProvider from '../omg-access-key/accessKeyMembershipsProvider'

const BreadContainer = styled.div`
  margin-top: 30px;
  color: ${props => props.theme.colors.B100};
  font-size: 14px;
`
const TitleContainer = styled.div`
  span {
    margin-left: 10px;
  }
`
const NameContainer = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  span {
    margin-left: 10px;
  }
`
const AssignRoleModalContainer = styled.div`
  display: flex;
  flex-direction: column;
  padding: 50px;
  position: relative;
  white-space: pre-line;
  width: 500px;

  h3 {
    margin-bottom: 20px;
  }

  .close-icon {
    position: absolute;
    right: 15px;
    top: 15px;
    cursor: pointer;
    color: ${props => props.theme.colors.S400};
  }

  .modal-buttons {
    display: flex;
    flex-direction: row;
    margin-top: 20px;

    button:first-child {
      margin-right: 10px;
    }
  }
`

const KeyDetailAccountsPage = ({ match: { params }, location: { search } }) => {
  const { keyType, keyId } = params
  const { search: _search } = queryString.parse(search)

  const [ assignRoleModal, setAssignRoleModal ] = useState({})
  const [ loading, setLoading ] = useState(false)

  const closeModals = () => {
    setAssignRoleModal({})
  }

  const submitRoleChange = async () => {
    setLoading(true)
    await console.log('TODO: submit role change')
    setLoading(false)
    closeModals()
  }

  const renderAssignRoleModal = () => {
    return (
      <AssignRoleModalContainer>
        <Icon name='Close' className='close-icon' onClick={closeModals} />
        <h3>Are you sure?</h3>
        <p>{`You are about to change account role\nfrom "${_.startCase(assignRoleModal.previousRole)}" to "${_.startCase(assignRoleModal.role)}" ?`}</p>
        <div className='modal-buttons'>
          <Button
            styleType='secondary'
            onClick={closeModals}
          >
            <span>Cancel</span>
          </Button>
          <Button
            styleType='primary'
            loading={loading}
            onClick={submitRoleChange}
          >
            <span>Yes, I want to change role</span>
          </Button>
        </div>
      </AssignRoleModalContainer>
    )
  }

  // eslint-disable-next-line react/prop-types
  const renderView = ({ memberships, loading }) => {
    if (memberships && !Array.isArray(memberships)) {
      memberships = [memberships]
    }

    const columns = [
      { key: 'account.name', title: 'NAME', sort: true },
      { key: 'account.id', title: 'ID', sort: false },
      { key: 'role', title: 'ACCOUNT ROLE', sort: false },
      { key: 'account.parent_id', title: 'ASSIGNED BY', sort: false },
      { key: 'created_at', title: 'ASSIGNED DATE', sort: true }
    ]

    const handleRoleSelect = (previousRole, role, row) => {
      setAssignRoleModal({ previousRole, role, accountId: row })
    }

    const rowRenderer = (key, data, rows) => {
      switch (key) {
        case 'account.name':
          return (
            <NameContainer key={key}>
              <Avatar image={_.get(rows, 'account.avatar.thumb')} />
              <span>{_.get(rows, 'account.name', '-')}</span>
            </NameContainer>
          )
        case 'account.id':
          return (
            <Id maxChar={20}>
              {_.get(rows, 'account.id', '-')}
            </Id>
          )
        case 'account.parent_id':
          return _.get(rows, 'account.parent_id', '-')
        case 'created_at':
          return moment(data).format()
        case 'role':
          const options = [
            { key: 'super_admin', value: 'Super Admin' },
            { key: 'admin', value: 'Admin' },
            { key: 'viewer', value: 'Viewer' },
            { key: 'none', value: 'None' }
          ]

          return (
            <Select
              onSelectItem={(item) => handleRoleSelect(data, item.key, _.get(rows, 'account.id'))}
              style={{ width: '150px' }}
              noBorder
              value={_.startCase(data)}
              options={options.filter(i => i.key !== data)}
            />
          )
        default:
          return data
      }
    }

    const getRows = () => {
      return memberships.map(membership => {
        return {
          id: membership.key_id,
          ...membership
        }
      })
    }

    return (
      <>
        <Modal
          isOpen={!_.isEmpty(assignRoleModal)}
          onRequestClose={closeModals}
          contentLabel='assign-role-modal'
          shouldCloseOnOverlayClick
        >
          {renderAssignRoleModal()}
        </Modal>

        <BreadContainer>
          <Breadcrumb
            items={[
              <Link key='keys-main' to={`/keys/${keyType}`}>Keys</Link>,
              <Link key='key-detail' to={`/keys/${keyType}/${keyId}`}>
                <Id withCopy={false} maxChar={20} style={{ marginRight: '0px' }}>{keyId}</Id>
              </Link>,
              <span key='assigned-accounts'>Assigned Accounts</span>
            ]}
          />
        </BreadContainer>
        <TopNavigation
          title={
            <TitleContainer>
              <Icon name='Key' />
              <span>Assigned Accounts</span>
            </TitleContainer>
          }
          buttons={[
            <Button
              key='assign-new-account-button'
              styleType='secondary'
              size='small'
            >
              <Icon name='Plus' style={{ marginRight: '10px' }} />
              <span>Assign New Account</span>
            </Button>
          ]}
          normalPlaceholder='Search by Account ID'
          divider={false}
        />
        <SortableTable
          rows={getRows()}
          columns={columns}
          loadingStatus={loading}
          rowRenderer={rowRenderer}
          hoverEffect={false}
          // isFirstPage={pagination.is_first_page}
          // isLastPage={pagination.is_last_page}
          // navigation={props.navigation}
          // pagination
        />
      </>
    )
  }

  return (
    <AccessKeyMembershipsProvider
      render={renderView}
      accessKeyId={keyId}
      filter={{
        matchAny: [
          {
            field: 'account.id',
            comparator: 'contains',
            value: _search || ''
          }
        ]
      }}
    />
  )
}

KeyDetailAccountsPage.propTypes = {
  match: PropTypes.object,
  location: PropTypes.object
}

export default KeyDetailAccountsPage
