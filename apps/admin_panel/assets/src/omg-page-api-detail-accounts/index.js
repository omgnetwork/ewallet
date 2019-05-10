import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Link } from 'react-router-dom'

import { Breadcrumb, Icon, Id } from '../omg-uikit'
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
  const renderView = ({ memberships }) => {
    console.log('memberships: ', memberships)
    return (
      <>
        <BreadContainer>
          <Breadcrumb
            items={[
              <Link key='keys' to={`/keys/${keyType}`}>Keys</Link>,
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
          searchBar={false}
          divider={false}
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
