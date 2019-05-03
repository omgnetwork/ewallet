import React from 'react'
import PropTypes from 'prop-types'
import { Link } from 'react-router-dom'
import styled from 'styled-components'

import { Breadcrumb, Icon, DetailRow, Tag, Button, NavCard } from '../omg-uikit'
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
const Content = styled.div`
  display: flex;
  flex-direction: row;
`
const DetailSection = styled.div`
  width: 50%;
  margin-right: 10%;
  .copy-icon {
    margin-left: 5px;
    color: ${props => props.theme.colors.B100};
    cursor: pointer;
  }

  .detail-section-header {
    margin-bottom: 15px;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
  }
`
const AsideSection = styled.div`
  width: 50%;
  .aside-section-header {
    text-align: right;
    margin-bottom: 20px;
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

      <Content>
        <DetailSection>
          <div className='detail-section-header'>
            <Tag
              icon='Option-Horizontal'
              title='Details'
            />
            <Button
              styleType='ghost'
              size='small'
              style={{ minWidth: 'initial' }}
            >
              <span>Edit</span>
            </Button>
          </div>
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

        <AsideSection>
          <div className='aside-section-header'>
            <Button
              styleType='secondary'
              size='small'
            >
              <Icon name='Plus' style={{ marginRight: '10px' }} />
              <span>Assign This Key</span>
            </Button>
          </div>
          <NavCard
            style={{ marginBottom: '10px' }}
            icon='Merchant'
            title='Assigned Accounts'
            subTitle='Lorem ipsum something something else'
            to='/'
          />
          <NavCard
            icon='Profile'
            title='Assigned Users'
            subTitle='Lorem ipsum something something else'
            to='/'
          />
        </AsideSection>
      </Content>
    </>
  )
}

ApiKeyDetailPage.propTypes = {
  match: PropTypes.object
}

export default ApiKeyDetailPage
