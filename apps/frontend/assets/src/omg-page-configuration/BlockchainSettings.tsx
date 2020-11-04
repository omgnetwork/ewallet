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
  blockchainEnabled: boolean,
  handleCancelClick: EffectCallback
  configurations: Object
  blockchainConfirmationsThreshold: {value: string, description: string}
  blockchainDepositPoolingInterval: {value: string, description: string}
  blockchainPollInterval: {value: string, description: string}
  blockchainStateSaveInterval: {value: string, description: string}
  blockchainSyncInterval: {value: string, description: string}
  blockchainTransactionPollInterval: {value: string, description: string}
  onChangeInput: Function
}

const BlockchainSettings = ({
  blockchainConfirmationsThreshold,
  blockchainDepositPoolingInterval,
  blockchainEnabled,
  blockchainPollInterval,
  blockchainStateSaveInterval,
  blockchainSyncInterval,
  blockchainTransactionPollInterval,
  configurations,
  handleCancelClick,
  onChangeInput
}: BlockchainSettingsProps) => {
  useEffect(() => {
    return handleCancelClick
  }, [handleCancelClick])

  const isPositiveInteger = (value: string | number): boolean => {
    const numericValue = Number(value)
    return numericValue > 0 && _.isInteger(numericValue)
  }

  const getDescription = (key: string): string => {
    return _.get(configurations, `${key}.description`)
  }

  const errorMsg = (key: string): string => {
    return `The ${key} should be a positive integer.`
  }

  const renderBlockchainSetting = configurations => {
    return (
      <>
        <h4>Blockchain Settings</h4>
        {!blockchainEnabled ? (
          <Grid>
            <ConfigRow
              disabled={true}
              name={'Blockchain JSON-RPC URL'}
              description={getDescription('blockchain_json_rpc_url')}
              value={configurations.blockchain_json_rpc_url.value}
            />
            <ConfigRow
              disabled={true}
              name={'Chain ID'}
              description={getDescription('blockchain_chain_id')}
              value={configurations.blockchain_chain_id.value}
            />
            <ConfigRow
              name={'Confirmations Threshold'}
              description={getDescription('blockchain_confirmations_threshold')}
              value={blockchainConfirmationsThreshold}
              onChange={onChangeInput('blockchainConfirmationsThreshold')}
              inputValidator={isPositiveInteger}
              inputErrorMessage={errorMsg('confirmations threshold')}
            />
            <ConfigRow
              name={'Deposit Polling Interval'}
              description={getDescription(
                'blockchain_deposit_pooling_interval'
              )}
              value={blockchainDepositPoolingInterval}
              onChange={onChangeInput('blockchainDepositPoolingInterval')}
              inputValidator={isPositiveInteger}
              inputErrorMessage={errorMsg('polling interval')}
            />
            <ConfigRow
              name={'Blockchain Poll Interval'}
              description={getDescription('blockchain_poll_interval')}
              value={blockchainPollInterval}
              onChange={onChangeInput('blockchainPollInterval')}
              inputValidator={isPositiveInteger}
              inputErrorMessage={errorMsg('poll interval')}
            />
            <ConfigRow
              name={'Blockchain State Save Interval'}
              description={getDescription('blockchain_state_save_interval')}
              value={blockchainStateSaveInterval}
              onChange={onChangeInput('blockchainStateSaveInterval')}
              inputValidator={isPositiveInteger}
              inputErrorMessage={errorMsg('state save interval')}
            />
            <ConfigRow
              name={'Blockchain Sync Interval'}
              description={getDescription('blockchain_sync_interval')}
              value={blockchainSyncInterval}
              onChange={onChangeInput('blockchainSyncInterval')}
              inputValidator={isPositiveInteger}
              inputErrorMessage={errorMsg('sync interval')}
            />
            <ConfigRow
              name={'Blockchain Tranaction Poll Interval'}
              description={getDescription(
                'blockchain_transaction_poll_interval'
              )}
              value={blockchainTransactionPollInterval}
              onChange={onChangeInput('blockchainTransactionPollInterval')}
              inputValidator={isPositiveInteger}
              inputErrorMessage={errorMsg('transaction poll interval')}
            />
          </Grid>
        ) : (
          <div> Blockchain is not enabled. </div>
        )}
      </>
    )
  }

  return (
    <>
      {!_.isEmpty(configurations) ? (
        <form>{renderBlockchainSetting(configurations)}</form>
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
