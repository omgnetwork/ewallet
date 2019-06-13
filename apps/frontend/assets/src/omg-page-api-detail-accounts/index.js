import React, { useState } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Link, withRouter } from 'react-router-dom'
import queryString from 'query-string'
import moment from 'moment'

import { fuzzySearch } from '../utils/search'
import SortableTable from '../omg-table'
import Modal from '../omg-modal'
import { Avatar, Button, Breadcrumb, Icon, Id, Select } from '../omg-uikit'
import TopNavigation from '../omg-page-layout/TopNavigation'
import AccessKeyMembershipsProvider from '../omg-access-key/accessKeyMembershipsProvider'
import AssignAccountToKeyModal from '../omg-assign-account-key-modal'

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
const ModalContainer = styled.div`
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
const RemoveCell = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 100%;
  width: 30px;
  height: 30px;
  margin-left: auto;
  margin-right: auto;
  transition: all 200ms ease-in-out;
  :hover {
    background-color: ${props => props.theme.colors.R300};
    color: white;
    cursor: pointer;
  }
`

const KeyDetailAccountsPageView = withRouter(
  ({
    memberships,
    membershipsLoading,
    updateRole,
    removeAccount,
    refetch,
    match: { params },
    location: { search },
    history
  }) => {
    const { keyType, keyId } = params

    const _memberships =
      memberships && !Array.isArray(memberships) ? [memberships] : memberships

    const { search: _search } = queryString.parse(search)
    const fuzzied =
      _memberships &&
      _memberships.filter(membership =>
        fuzzySearch(_search, membership.account_id)
      )

    const [roleModalOpen, setRoleModalOpen] = useState(false)
    const [deleteModalOpen, setDeleteModalOpen] = useState(false)
    const [assignAccountToKeyModal, setAssignAccountToKeyModal] = useState(
      false
    )
    const [modalContent, setModalContent] = useState({})
    const [loading, setLoading] = useState(false)

    const columns = [
      { key: 'account.name', title: 'NAME', sort: true },
      { key: 'account.id', title: 'ID', sort: false },
      { key: 'role', title: 'ACCOUNT ROLE', sort: false },
      { key: 'created_at', title: 'ASSIGNED DATE', sort: true },
      { key: 'delete', title: 'REMOVE', sort: false, align: 'center' }
    ]

    const closeModals = () => {
      setRoleModalOpen(false)
      setDeleteModalOpen(false)
      setTimeout(() => {
        setModalContent({})
      }, 200)
    }

    const submitRoleChange = async () => {
      setLoading(true)
      const { accountId, role } = modalContent
      await updateRole({ accountId, role })
      setLoading(false)
      closeModals()
    }

    const submitRemoveAccount = async () => {
      setLoading(true)
      const { accountId } = modalContent
      await removeAccount({ accountId })
      setLoading(false)
      closeModals()
    }

    const renderDeleteRoleModal = () => {
      return (
        <ModalContainer>
          <Icon name='Close' className='close-icon' onClick={closeModals} />
          <h3>Remove this account?</h3>
          <p>You are about to remove this account from this key.</p>
          <p>Are you sure you want to do that?</p>
          <div className='modal-buttons'>
            <Button styleType='ghost' onClick={closeModals}>
              <span>Cancel</span>
            </Button>
            <Button
              styleType='danger'
              loading={loading}
              onClick={submitRemoveAccount}
            >
              <span>Yes, I want to remove it</span>
            </Button>
          </div>
        </ModalContainer>
      )
    }

    const renderAssignRoleModal = () => {
      return (
        <ModalContainer>
          <Icon name='Close' className='close-icon' onClick={closeModals} />
          <h3>Are you sure?</h3>
          <p>{`You are about to change account role\nfrom "${_.startCase(
            modalContent.previousRole
          )}" to "${_.startCase(modalContent.role)}" ?`}</p>
          <div className='modal-buttons'>
            <Button styleType='secondary' onClick={closeModals}>
              <span>Cancel</span>
            </Button>
            <Button
              styleType='primary'
              loading={loading}
              onClick={submitRoleChange}
            >
              <span>Yes, I want to change it</span>
            </Button>
          </div>
        </ModalContainer>
      )
    }

    const handleRoleSelect = (previousRole, role, accountId) => {
      setModalContent({ previousRole, role, accountId })
      setRoleModalOpen(true)
    }

    const handleRemoveAccount = accountId => {
      setModalContent({ accountId })
      setDeleteModalOpen(true)
    }

    const rowRenderer = (key, data, rows) => {
      const accountId = _.get(rows, 'account.id')
      switch (key) {
        case 'delete':
          return (
            <RemoveCell onClick={() => handleRemoveAccount(accountId)}>
              <Icon name='Close' />
            </RemoveCell>
          )
        case 'account.name':
          return (
            <NameContainer key={key}>
              <Avatar
                name={_.get(rows, 'account.name')}
                image={_.get(rows, 'account.avatar.thumb')}
              />
              <span>{_.get(rows, 'account.name', '-')}</span>
            </NameContainer>
          )
        case 'account.id':
          return <Id maxChar={20}>{accountId || '-'}</Id>
        case 'account.parent_id':
          return _.get(rows, 'account.parent_id', '-')
        case 'created_at':
          return moment(data).format()
        case 'role':
          const options = [
            { key: 'admin', value: 'Admin' },
            { key: 'viewer', value: 'Viewer' }
          ]
          return (
            <Select
              onSelectItem={item => handleRoleSelect(data, item.key, accountId)}
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
      return fuzzied && fuzzied.length
        ? fuzzied.map(membership => ({
          id: membership.account_id,
          ...membership
        }))
        : []
    }
    console.log(membershipsLoading)
    return (
      <>
        <AssignAccountToKeyModal
          keyId={keyId}
          open={assignAccountToKeyModal}
          onRequestClose={() => setAssignAccountToKeyModal(false)}
          onSubmitSuccess={() => {
            const filter = {
              matchAny: [
                {
                  field: 'account.id',
                  comparator: 'contains',
                  value: _search || ''
                }
              ]
            }
            refetch(filter)
          }}
        />

        <Modal
          shouldReturnFocusAfterClose={false}
          isOpen={roleModalOpen}
          onRequestClose={closeModals}
          contentLabel='assign-role-modal'
          shouldCloseOnOverlayClick
        >
          {renderAssignRoleModal()}
        </Modal>

        <Modal
          shouldReturnFocusAfterClose={false}
          isOpen={deleteModalOpen}
          onRequestClose={closeModals}
          contentLabel='delete-role-modal'
          shouldCloseOnOverlayClick
        >
          {renderDeleteRoleModal()}
        </Modal>

        <BreadContainer>
          <Breadcrumb
            items={[
              <Link key='keys-main' to={`/keys/${keyType}`}>
                Keys
              </Link>,
              <Link key='key-detail' to={`/keys/${keyType}/${keyId}`}>
                <Id
                  withCopy={false}
                  maxChar={20}
                  style={{ marginRight: '0px' }}
                >
                  {keyId}
                </Id>
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
              onClick={() => setAssignAccountToKeyModal(true)}
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
          rowRenderer={rowRenderer}
          columns={columns}
          loadingStatus={membershipsLoading}
          hoverEffect={false}
        />
      </>
    )
  }
)

KeyDetailAccountsPageView.propTypes = {
  memberships: PropTypes.array,
  membershipsLoading: PropTypes.bool,
  updateRole: PropTypes.func,
  removeAccount: PropTypes.func,
  refetch: PropTypes.func
}

const KeyDetailAccountsPage = ({ match: { params }, location: { search } }) => {
  const { keyId } = params
  const { search: _search } = queryString.parse(search)

  return (
    <AccessKeyMembershipsProvider
      render={KeyDetailAccountsPageView}
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
