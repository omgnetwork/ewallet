/* eslint-disable react/prop-types */
import React, { EffectCallback, useEffect } from 'react'
import styled from 'styled-components'
import _ from 'lodash'

import { LoadingSkeleton } from 'omg-uikit'
import ConfigRow from './ConfigRow'

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

interface BlockchainSettingsProps {
  blockchainEnabled: boolean
  handleCancelClick: EffectCallback
  configurations: { [key: string]: { description: string; key: string } }
  onChangeInput: Function
}

const BlockchainSettings = (props: BlockchainSettingsProps) => {
  useEffect(() => {
    return props.handleCancelClick
  }, [props.handleCancelClick])

  const isPositiveInteger = (value: string | number): boolean => {
    const numericValue = Number(value)
    return numericValue > 0 && _.isInteger(numericValue)
  }

  const errorMsg = (key: string): string => {
    return `${key} should be a positive integer.`
  }

  interface displaySettings {
    [key: string]: {
      displayName: string
      disableUpdate: boolean
      inputValidator?: (...args: any) => boolean
      position: number
    }
  }

  const settings: displaySettings = {
    blockchain_json_rpc_url: {
      displayName: 'Blockchain JSON-RPC URL',
      disableUpdate: true,
      position: 0
    },
    blockchain_chain_id: {
      displayName: 'Blockchain Chain ID',
      disableUpdate: true,
      position: 1
    },
    blockchain_confirmations_threshold: {
      displayName: 'Blockchain Confirmations Threshold',
      disableUpdate: false,
      inputValidator: isPositiveInteger,
      position: 2
    },
    blockchain_deposit_pooling_interval: {
      displayName: 'Blockchain Deposit Polling Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger,
      position: 3
    },
    blockchain_transaction_poll_interval: {
      displayName: 'Blockchain Transaction Poll Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger,
      position: 4
    },
    blockchain_state_save_interval: {
      displayName: 'Blockchain State Save Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger,
      position: 5
    },
    blockchain_sync_interval: {
      displayName: 'Blockchain Sync Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger,
      position: 6
    },
    blockchain_poll_interval: {
      displayName: 'Blockchain Poll Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger,
      position: 7
    },
  }

  const renderBlockchainSettings = () => {
    const sortedConfigurationList = _.sortBy(
      _.values(_.pick(props.configurations, _.keys(settings))),
      config => settings[config.key].position
    )

    return (
      <>
        <h4>Blockchain Settings</h4>
        {props.blockchainEnabled ? (
          <Grid>
            {sortedConfigurationList.map((item, index) => {
              const { key, description } = item
              const camelCaseKey = _.camelCase(item.key)
              return (
                <ConfigRow
                  key={index}
                  disabled={settings[key].disableUpdate}
                  name={settings[key].displayName}
                  value={props[camelCaseKey]}
                  description={description}
                  onChange={props.onChangeInput(camelCaseKey)}
                  inputValidator={settings[key].inputValidator}
                  inputErrorMessage={errorMsg(key)}
                />
              )
            })}
          </Grid>
        ) : (
          <div> Blockchain is not enabled. </div>
        )}
      </>
    )
  }

  return (
    <>
      {!_.isEmpty(props.configurations) ? (
        <form>{renderBlockchainSettings()}</form>
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
