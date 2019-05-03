import React, { useState } from 'react'
import PropTypes from 'prop-types'
import { Link } from 'react-router-dom'
import styled from 'styled-components'

import TopNavigation from '../omg-page-layout/TopNavigation'
import { Breadcrumb, Icon, DetailRow, Tag, Button, NavCard, Select, Switch } from '../omg-uikit'

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
  width: 45%;
  margin-right: 10%;
  .copy-icon {
    margin-left: 5px;
    color: ${props => props.theme.colors.B100};
    cursor: pointer;
  }

  .detail-section-header {
    height: 36px;
    margin-bottom: 15px;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
  }

  .button-group {
    margin-top: 30px;
    text-align: right;
  }
`
const AsideSection = styled.div`
  width: 45%;
  .aside-section-header {
    text-align: right;
    margin-bottom: 20px;
  }
  .nav-card {
    margin-bottom: 10px;
  }
`

const ApiKeyDetailPage = ({ match: { params }, history, location: { pathname } }) => {
  const { keyType, keyDetail } = params
  const [ view, setView ] = useState('read')

  const handleSave = () => {
    console.log('updating...')
    setView('read')
  }

  const renderReadView = () => (
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
            onClick={() => setView('edit')}
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
          className='nav-card'
          icon='Merchant'
          title='Assigned Accounts'
          subTitle='Lorem ipsum something something else'
          to={`${pathname}/assigned-accounts`}
        />
        <NavCard
          icon='Profile'
          title='Assigned Users'
          subTitle='Lorem ipsum something something else'
          to={`${pathname}/assigned-users`}
        />
      </AsideSection>
    </Content>
  )

  const renderEditView = () => (
    <Content>
      <DetailSection>
        <div className='detail-section-header'>
          <Tag
            icon='Option-Horizontal'
            title='Details'
          />
        </div>
        <DetailRow
          label='Label'
          value={
            <Select
              noBorder
              normalPlaceholder='Label'
              value='None'
              options={[
                { key: 'hi', value: 'HI' },
                { key: 'yo', value: 'YO' }
              ]}
            />
          }
        />
        <DetailRow
          label='Global Role'
          value={
            <Select
              noBorder
              normalPlaceholder='Global Role'
              value='None'
              options={[
                { key: 'hi', value: 'HI' },
                { key: 'yo', value: 'YO' },
                { key: 'so', value: 'SO' }
              ]}
            />
          }
        />
        <DetailRow
          label='Status'
          value={
            <>
              <span style={{ marginRight: '10px' }}>
                Inactive
              </span>
              <Switch
                open={false}
                onClick={console.log}
              />
            </>
          }
        />
        <div className='button-group'>
          <Button
            styleType='ghost'
            onClick={() => setView('read')}
            style={{ minWidth: 'initial' }}
          >
            <span>Cancel</span>
          </Button>
          <Button
            styleType='primary'
            onClick={handleSave}
            style={{ minWidth: 'initial', marginLeft: '10px' }}
          >
            <span>Save</span>
          </Button>
        </div>
      </DetailSection>
    </Content>
  )

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

      {view === 'read'
        ? renderReadView()
        : renderEditView()}
    </>
  )
}

ApiKeyDetailPage.propTypes = {
  match: PropTypes.object,
  location: PropTypes.object,
  history: PropTypes.object
}

export default ApiKeyDetailPage
