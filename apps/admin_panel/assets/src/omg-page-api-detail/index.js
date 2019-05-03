import React from 'react'
import PropTypes from 'prop-types'
import { Link } from 'react-router-dom'
import styled from 'styled-components'

import { Breadcrumb, Icon, DetailRow } from '../omg-uikit'
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
const DetailSection = styled.div`
  width: 40%;
  .copy-icon {
    margin-left: 5px;
    color: ${props => props.theme.colors.B100};
    cursor: pointer;
  }
`

const ApiKeyDetailPage = ({ match: { params } }) => {
  const { keyType, keyDetail } = params

  return (
    <>
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
      />

      <DetailSection>
        <DetailRow
          label='Type'
          value={<div>Admin Key</div>}
        />
        <DetailRow
          label='ID'
          value={
            <>
              <div>Admin Key</div>
              <Icon className='copy-icon' name='Copy' />
            </>
          }
        />
        <DetailRow
          label='Label'
          value={<div>None</div>}
        />
        <DetailRow
          label='Global Role'
          value={<div>None</div>}
        />
        <DetailRow
          label='Created by'
          value={<div>None</div>}
        />
        <DetailRow
          label='Created date'
          icon='Time'
          value={<div>None</div>}
        />
        <DetailRow
          label='Status'
          value={<div>Inactive</div>}
        />
      </DetailSection>
    </>
  )
}

ApiKeyDetailPage.propTypes = {
  match: PropTypes.object
}

export default ApiKeyDetailPage
