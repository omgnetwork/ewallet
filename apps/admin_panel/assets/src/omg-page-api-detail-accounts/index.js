import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Link } from 'react-router-dom'

import { Breadcrumb, Icon } from '../omg-uikit'
import TopNavigation from '../omg-page-layout/TopNavigation'

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
  const { keyType, keyDetail } = params

  return (
    <>
      <BreadContainer>
        <Breadcrumb
          items={[
            <Link key='keys' to={`/keys/${keyType}`}>Keys</Link>,
            <Link key='key-detail' to={`/keys/${keyType}/${keyDetail}`}>{keyDetail}</Link>,
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

KeyDetailAccountsPage.propTypes = {
  match: PropTypes.object
}

export default KeyDetailAccountsPage
