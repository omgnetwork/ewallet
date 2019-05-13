import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Link } from 'react-router-dom'

import SortableTable from '../omg-table'
import { Button, Breadcrumb, Icon, Id } from '../omg-uikit'
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

const KeyDetailAccountsPage = ({ match: { params } }) => {
  const { keyType, keyId } = params

  // eslint-disable-next-line react/prop-types
  const renderView = ({ memberships, loading }) => {
    if (!Array.isArray(memberships)) {
      memberships = [memberships]
    }
    console.log('memberships: ', memberships)
    console.log('loading: ', loading)

    const columns = [
      { key: 'account.name', title: 'NAME', sort: true },
      { key: 'account.id', title: 'ID', sort: false },
      { key: 'role', title: 'ACCOUNT ROLE', sort: false },
      { key: 'account.parent_id', title: 'ASSIGNED BY', sort: false },
      { key: 'created_at', title: 'ASSIGNED DATE', sort: true }
    ]

    const rowRenderer = (key, data, rows) => {
      console.log(key)
      console.log('data: ', data)
      console.log('rows: ', rows)
      switch (key) {
        case 'account.name':
          return _.get(rows, 'account.name', '-')
        case 'account.id':
          return _.get(rows, 'account.id', '-')
        default:
          return data
      }
    }

    const getRows = () => {
      return memberships
        ? memberships.map(i => {
          return {
            ...i
          }
        })
        : []
    }

    return (
      <>
        <BreadContainer>
          <Breadcrumb
            items={[
              <Link key='keys' to={`/keys/${keyType}`}>Keys</Link>,
              <Link key='key-detail' to={`/keys/${keyType}/${keyId}`}>
                <Id withCopy={false} maxChar={20} style={{ marginRight: '0px' }}>{_.get(memberships, 'key.access_key', keyId)}</Id>
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
    />
  )
}

KeyDetailAccountsPage.propTypes = {
  match: PropTypes.object
}

export default KeyDetailAccountsPage
