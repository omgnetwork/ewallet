/* eslint-disable react/prop-types */
import React, { EffectCallback, useEffect } from 'react'
import styled from 'styled-components'
import _ from 'lodash'

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

  const settings = {
    blockchain_chain_id: {
      displayName: 'Blockchain Chain ID',
      disableUpdate: true
    },
    blockchain_confirmations_threshold: {
      displayName: 'Blockchain Confirmations Threshold',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_deposit_pooling_interval: {
      displayName: 'Blockchain Deposit Polling Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_json_rpc_url: {
      displayName: 'Blockchain Deposit Polling Interval',
      disableUpdate: true
    },
    blockchain_poll_interval: {
      displayName: 'Blockchain Poll Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_state_save_interval: {
      displayName: 'Blockchain State Save Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_sync_interval: {
      displayName: 'Blockchain Sync Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_transaction_poll_interval: {
      displayName: 'Blockchain Tranaction Poll Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    }
  }

  const renderBlockchainSettings = () => {
    const sortedConfigurationList = _.sortBy(
      _.values(_.pick(props.configurations, _.keys(settings))),
      ['position']
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
