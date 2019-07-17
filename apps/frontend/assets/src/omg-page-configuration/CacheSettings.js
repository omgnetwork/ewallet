/* eslint-disable react/prop-types */
import React from 'react'
import styled from 'styled-components'

import ConfigRow from './ConfigRow'
import { LoadingSkeleton } from '../omg-uikit'

const LoadingSkeletonContainer = styled.div`
  margin-top: 50px;
  > div {
    margin-bottom: 20px;
  }
`
const SubSettingContainer = styled.div`
  > div {
    margin-left: 25px;
    padding: 0 20px;
    background-color: ${props => props.theme.colors.S100};
    border-radius: 4px;
    border: 1px solid transparent;
    div:first-child {
      flex: 0 0 175px;
    }
  }
`
const CacheSettings = (props) => {
  const renderCacheSetting = (configurations) => {
    return (
      <>
        <h4>Cache Settings</h4>
        <ConfigRow
          name={'Balance Caching Strategy'}
          description={configurations.balance_caching_strategy.description}
          value={props.balanceCachingStrategy}
          onSelectItem={props.onSelectBalanceCache}
          type='select'
          options={configurations.balance_caching_strategy.options.map(
            option => ({
              key: option,
              value: option
            })
          )}
        />
        {props.balanceCachingStrategy === 'since_last_cached' && (
          <SubSettingContainer>
            <div>
              <ConfigRow
                name={'Balance Caching Reset Frequency'}
                description={
                  configurations.balance_caching_reset_frequency.description
                }
                value={props.balanceCachingResetFrequency}
                placeholder={'ie. 10'}
                onChange={props.onChangeInput('balanceCachingResetFrequency')}
              />
            </div>
          </SubSettingContainer>
        )}
      </>
    )
  }
  return (
    <>
      {!_.isEmpty(props.configurations) ? (
        <form>
          {renderCacheSetting(props.configurations)}
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

export default CacheSettings
