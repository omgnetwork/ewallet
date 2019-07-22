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
const SubSettingContainer = styled.div`
  width: 100%;
  padding: 20px 40px;
  background-color: ${props => props.theme.colors.BL100};
  border-radius: 4px;
  border: 1px solid transparent;
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
          {props.enableBlockchain && (
            <SubSettingContainer>
              <ConfigRow
                name={'Network'}
                value={props.blockchainNetwork}
                onSelectItem={props.onSelectBlockchainNetwork}
                onChange={props.onChangeInput('blockchainNetwork')}
                type='select'
                options={configurations.blockchain_netowrk
                  ? configurations.blockchain_network.options.map(option => ({
                    key: option,
                    value: option
                  }))
                  : []
                }
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
