import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Link } from 'react-router-dom'
import queryString from 'query-string'
import moment from 'moment'

import SortableTable from '../omg-table'
import { Avatar, Button, Breadcrumb, Icon, Id } from '../omg-uikit'
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

const KeyDetailAccountsPage = ({ match: { params }, location: { search } }) => {
  const { keyType, keyId } = params
  const { search: _search } = queryString.parse(search)

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
          return _.get(rows, 'account.id', '-')
        case 'account.parent_id':
          return _.get(rows, 'account.parent_id', '-')
        case 'created_at':
          return moment(data).format()
        default:
          return data
      }
    }

    return (
      <>
        <BreadContainer>
          <Breadcrumb
            items={[
              <Link key='keys-main' to={`/keys/${keyType}`}>Keys</Link>,
              <Link key='key-detail' to={`/keys/${keyType}/${keyId}`}>
                <Id withCopy={false} maxChar={20} style={{ marginRight: '0px' }}>{_.get(memberships, '[0].key.access_key', keyId)}</Id>
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
          rows={memberships}
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
