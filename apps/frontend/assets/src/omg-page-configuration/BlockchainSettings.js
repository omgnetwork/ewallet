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
const Grid = styled.div`
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
`

const BlockchainSettings = (props) => {
  useEffect(() => {
    return props.handleCancelClick
  }, [])

  const renderBlockchainSetting = (configurations) => {
    return (
      <>
        <h4>Blockchain Settings</h4>
        <Grid>
          <ConfigRow
            name={'Enable Ethereum Blockchain Connection'}
            description={'Blockchain is cool'} // TODO: configurations.enable_blockchain.description}
            value={props.enableBlockchain}
            onChange={props.onChangeEnableBlockchain}
            type='boolean'
          />
        </Grid>
      </>
    )
  }

  return (
    <>
      {!_.isEmpty(props.configurations) ? (
        <form>
          {renderBlockchainSetting(props.configurations)}
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

export default BlockchainSettings
