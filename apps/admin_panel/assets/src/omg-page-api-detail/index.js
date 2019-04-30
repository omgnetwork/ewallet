import React from 'react'
import PropTypes from 'prop-types'
import { Link } from 'react-router-dom'
import styled from 'styled-components'

import { Breadcrumb } from '../omg-uikit'

const ApiKeyDetailPageStyles = styled.div`
  background-color: red;
`

const BreadContainer = styled.div`
  padding: 20px 0 0 0;
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`

const ApiKeyDetailPage = ({ match: { params } }) => {
  console.log('params: ', params)
  return (
    <ApiKeyDetailPageStyles>
      <BreadContainer>
        <Breadcrumb
          items={[
            <Link key='keys' to={'/keys/'}>Keys</Link>,
            'toto'
          ]}
        />
      </BreadContainer>
    </ApiKeyDetailPageStyles>
  )
}

ApiKeyDetailPage.propTypes = {
  match: PropTypes.object
}

export default ApiKeyDetailPage
