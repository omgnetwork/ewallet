/* eslint-disable react/prop-types */
import React, { useEffect } from 'react'
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
  width: 100%;
  padding: 20px 40px;
  margin-right: 60px;
  background-color: ${props => props.theme.colors.BL100};
  border-radius: 4px;
  border: 1px solid transparent;
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
`
const Grid = styled.div`
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
`

const CacheSettings = (props) => {
  useEffect(() => {
    return props.handleCancelClick
  }, [])

  const renderCacheSetting = (configurations) => {
    return (
      <>
        <h4>Cache Settings</h4>
        <Grid>
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
              <ConfigRow
                name={'Balance Caching Reset Frequency'}
                description={
                  configurations.balance_caching_reset_frequency.description
                }
                value={props.balanceCachingResetFrequency}
                placeholder={'ie. 10'}
                onChange={props.onChangeInput('balanceCachingResetFrequency')}
              />
            </SubSettingContainer>
          )}
        </Grid>
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
          <LoadingSkeleton />
        </LoadingSkeletonContainer>
      )}
    </>
  )
}

export default CacheSettings
