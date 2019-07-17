/* eslint-disable react/prop-types */
import React from 'react'
import styled from 'styled-components'

import ConfigRow from './ConfigRow'
import AccountsFetcher from '../omg-account/accountsFetcher'
import { createSearchMasterAccountQuery } from '../omg-account/searchField'
import AccountSelect from '../omg-account-select'
import { LoadingSkeleton, Input, Icon } from '../omg-uikit'

const LoadingSkeletonContainer = styled.div`
  margin-top: 50px;
  > div {
    margin-bottom: 20px;
  }
`
const InputPrefixContainer = styled.div`
  position: relative;
  i {
    position: absolute;
    right: -20px;
    top: 4px;
    visibility: ${props => (props.hide ? 'hidden' : 'visible')};
    opacity: 0;
    font-size: 8px;
    cursor: pointer;
    padding: 10px;
  }
  :hover > i {
    opacity: 1;
  }
`
const InputsPrefixContainer = styled.div`
  ${InputPrefixContainer} {
    :not(:first-child) {
      margin-top: 20px;
    }
  }
`
const PrefixContainer = styled.div`
  text-align: left;
  a {
    display: block;
    margin-top: 20px;
    color: ${props =>
    props.active ? props.theme.colors.BL400 : props.theme.colors.S500};
  }
`
const Grid = styled.div`
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
`

const GlobalSettings = (props) => {
  const renderGlobalSetting = (configurations) => {
    return (
      <>
        <h4>Global Settings</h4>
        <Grid>
          <AccountsFetcher
            query={createSearchMasterAccountQuery(props.masterAccount)}
            render={({ data }) => {
              return (
                <ConfigRow
                  name={'Master Account'}
                  description={configurations.master_account.description}
                  value={props.masterAccount}
                  onSelectItem={props.onSelectMasterAccount}
                  onChange={props.onChangeInput('masterAccount')}
                  type='select'
                  options={data.map(account => ({
                    key: account.id,
                    value: <AccountSelect account={account} />,
                    ...account
                  }))}
                />
              )
            }}
          />
          <ConfigRow
            name={'Base URL'}
            description={configurations.base_url.description}
            value={props.baseUrl}
            onChange={props.onChangeInput('baseUrl')}
            inputValidator={value => value.length > 0}
            inputErrorMessage={'This field shouldn\'t be empty'}
          />
          <ConfigRow
            name={'Redirect URL Prefixes'}
            description={configurations.redirect_url_prefixes.description}
            valueRenderer={() => {
              return (
                <InputsPrefixContainer>
                  {props.redirectUrlPrefixes.map((prefix, index) => (
                    <InputPrefixContainer
                      key={index}
                      hide={props.redirectUrlPrefixes.length === 1}
                    >
                      <Input
                        value={props.redirectUrlPrefixes[index]}
                        onChange={props.onChangeInputredirectUrlPrefixes(index)}
                        normalPlaceholder={`ie. https://website${index}.com`}
                      />
                      <Icon
                        name='Close'
                        onClick={props.onClickRemovePrefix(index)}
                      />
                    </InputPrefixContainer>
                  ))}
                  <PrefixContainer active={!props.isAddPrefixButtonDisabled()}>
                    <a onClick={props.onClickAddPrefix}>+ Add Prefix</a>
                  </PrefixContainer>
                </InputsPrefixContainer>
              )
            }}
          />
          <ConfigRow
            name={'Enable Standalone'}
            description={configurations.enable_standalone.description}
            value={props.enableStandalone}
            onChange={props.onChangeRadio}
            type='boolean'
          />
          <ConfigRow
            name={'Maximum Records Per Page'}
            description={configurations.max_per_page.description}
            value={String(props.maxPerPage)}
            inputType='number'
            onChange={props.onChangeInput('maxPerPage')}
            inputValidator={value => Number(value) >= 1}
            inputErrorMessage='invalid number'
            suffix='Items'
          />
          <ConfigRow
            name={'Minimum Password Length'}
            description={configurations.min_password_length.description}
            value={String(props.minPasswordLength)}
            inputType='number'
            onChange={props.onChangeInput('minPasswordLength')}
            inputValidator={value => Number(value) >= 1}
            inputErrorMessage='invalid number'
            suffix='Characters'
          />
          <ConfigRow
            name={'Forget Password Request Lifetime'}
            description={
              configurations.forget_password_request_lifetime.description
            }
            value={String(props.forgetPasswordRequestLifetime)}
            inputType='number'
            onChange={props.onChangeInput('forgetPasswordRequestLifetime')}
            inputValidator={value => Number(value) >= 1}
            inputErrorMessage='invalid number'
            suffix='Mins'
          />
          <ConfigRow
            name={'Pre Auth Token Lifetime'}
            description={configurations.pre_auth_token_lifetime.description}
            value={String(props.preAuthTokenLifetime)}
            inputType='number'
            onChange={props.onChangeInput('preAuthTokenLifetime')}
            inputValidator={value => Number(value) >= 0}
            inputErrorMessage='invalid number'
            suffix='Secs'
          />
          <ConfigRow
            name={'Auth Token Lifetime'}
            description={configurations.auth_token_lifetime.description}
            value={String(props.authTokenLifetime)}
            inputType='number'
            onChange={props.onChangeInput('authTokenLifetime')}
            inputValidator={value => Number(value) >= 0}
            inputErrorMessage='invalid number'
            suffix='Secs'
          />
        </Grid>
      </>
    )
  }
  return (
    <>
      {!_.isEmpty(props.configurations) ? (
        <form>
          {renderGlobalSetting(props.configurations)}
        </form>
      ) : (
        <LoadingSkeletonContainer>
          <LoadingSkeleton width={'150px'} />
          <LoadingSkeleton />
          <LoadingSkeleton />
        </LoadingSkeletonContainer>
      )}
    </>
  )
}

export default GlobalSettings
