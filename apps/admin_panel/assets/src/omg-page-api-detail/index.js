import React from 'react'
import PropTypes from 'prop-types'
import { Link } from 'react-router-dom'
import styled from 'styled-components'

import { Breadcrumb, Icon, Button } from '../omg-uikit'
import TopNavigation from '../omg-page-layout/TopNavigation'

const ApiKeyDetailPageStyles = styled.div`
`
const BreadContainer = styled.div`
  padding: 20px 0 0 0;
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`
const TitleContainer = styled.div`
  span {
    margin-left: 10px;
  }
`

const ApiKeyDetailPage = ({ match: { params } }) => {
  const { keyType, keyDetail } = params

  return (
    <ApiKeyDetailPageStyles>
      <BreadContainer>
        <Breadcrumb
          items={[
            <Link key='keys' to={`/keys/${keyType}`}>Keys</Link>,
            keyDetail
          ]}
        />
      </BreadContainer>
      <TopNavigation
        title={
          <TitleContainer>
            <Icon name='Key' />
            <span>{keyDetail}</span>
          </TitleContainer>
        }
        searchBar={false}
        divider={false}
        buttons={[
          <Button
            key='edit'
            styleType='secondary'
          >
            Edit
          </Button>
        ]}
      />
    </ApiKeyDetailPageStyles>
  )
}

ApiKeyDetailPage.propTypes = {
  match: PropTypes.object
}

export default ApiKeyDetailPage
