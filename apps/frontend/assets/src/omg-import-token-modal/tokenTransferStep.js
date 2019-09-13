import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import web3Utils from 'web3-utils'

import { Button, Icon } from '../omg-uikit'
import Accordion from '../omg-uikit/animation/Accordion'
import { transfer } from '../omg-transaction/action'
import { getWalletById } from '../omg-wallet/action'
import { sendErc20Transaction, estimateGasFromTransaction } from '../omg-web3/action'
import { formatAmount } from '../utils/formatter'
import BlockchainWalletSelect from '../omg-blockchain-wallet-select'
import { selectBlockchainWalletBalance, selectBlockchainWalletById } from '../omg-blockchain-wallet/selector'
import TokenSelect from '../omg-token-select'
import { selectNetwork, selectCurrentAddress } from '../omg-web3/selector'
import { weiToGwei, gweiToWei } from '../omg-web3/web3Utils'
import {
  Form,
  Title,
  PendingIcon,
  SuccessIcon,
  ButtonContainer,
  Error,
  FromToContainer,
  StyledSelectInput,
  StyledInput,
  Label,
  Collapsable,
  FeeContainer,
  GrayFeeContainer,
  CollapsableHeader,
  CollapsableContent,
  Links
} from './styles'
import { ethExplorerMetamaskNetworkMap } from '../omg-web3/constants'

class TokenTransferStep extends Component {
  static propTypes = {
    to: PropTypes.string,
    onRequestClose: PropTypes.func,
    selectBlockchainWalletById: PropTypes.func,
    selectCurrentAddress: PropTypes.string,
    sendErc20Transaction: PropTypes.func,
    estimateGasFromTransaction: PropTypes.func,
    network: PropTypes.number,
    token: PropTypes.object
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  state = {
    fromAddress: '',
    fromTokenAmount: '',
    toTokenAmount: '',
    toAddress: '',
    settingsOpen: false,
    transactionFee: 0,
    amountToSend: 0,
    step: 1,
    gasLimit: 21000,
    gasPrice: '',
    metaData: '',
    fromTokenSelected: {}
  }
  async componentDidMount () {
    this.setGasPrice()
    this.setState({
      fromAddress: this.props.selectCurrentAddress
    })
  }

  componentDidUpdate (prevProps, prevState) {
    const { toAddress, fromTokenAmount, fromTokenSelected } = this.state
    if (
      fromTokenAmount &&
      toAddress &&
      fromTokenSelected &&
      ((prevState.toAddress !== toAddress) ||
        this.props.token.id !== prevState.fromTokenSelected.id ||
        this.state.fromTokenAmount !== prevState.fromTokenAmount)
    ) {
      this.setGasPrice()
    }
  }

  setGasPrice = async () => {
    const { estimateGasFromTransaction } = this.props
    if (web3Utils.isAddress(this.state.toAddress)) {
      const { data: { gas } } = await estimateGasFromTransaction(this.getTransactionPayload())
      this.setState({ gasPrice: weiToGwei(gas) })
    }
  }

  onClickSetting = () => {
    this.setState(oldState => ({ settingsOpen: !oldState.settingsOpen }))
  }
  onChangeAmount = type => e => {
    this.setState({ [`${type}Amount`]: e.target.value })
  }
  onSelectToAddressSelect = item => {
    if (item) {
      this.setState({
        toAddress: item.key,
        toAddressSelect: true
      })
    } else {
      this.setState({
        toAddress: '',
        toAddressSelect: false,
        toTokenSearchToken: ''
      })
    }
  }
  getTransactionPayload = () => {
    const {
      fromAddress,
      fromTokenAmount,
      gasLimit,
      gasPrice
    } = this.state

    const payload = {
      from: fromAddress,
      to: this.props.to,
      value: formatAmount(fromTokenAmount, this.props.token.subunit_to_unit),
      tokenAddress: this.props.token.blockchain_address,
      gas: gasLimit || undefined,
      gasPrice: gasPrice ? gweiToWei(gasPrice) : undefined
    }
    return payload
  }
  getTransactionFee = () => {
    return this.state.gasPrice
      ? weiToGwei(this.state.gasPrice)
        .multipliedBy(this.state.gasLimit)
        .toFixed()
      : 0
  }
  onSubmit = async e => {
    this.setState({ submitting: true })
    e.preventDefault()
    this.props.sendErc20Transaction({
      transaction: this.getTransactionPayload(),
      onTransactionHash: hash => {
        this.setState({ step: 3, txHash: String(hash) })
      },
      onReceipt: () => {
        console.log('onReceipt')
      },
      onConfirmation: () => {
        this.setState({ step: 4 })
      },
      onError: error => {
        this.setState({ submitting: false, error: _.get(error, 'message') })
      }
    })
  }
  onRequestClose = () => {
    this.props.onRequestClose()
    this.setState({ submitting: false })
  }
  renderToSelectWalletValue = value => {
    return (
      <BlockchainWalletSelect
        icon='Wallet'
        topRow={value}
        bottomRow={'master_account | blockchain_deposit_address'}
      />
    )
  }
  renderToSelectWalletOption = data => {
    return data
      ? data
        .map(d => {
          return {
            key: d.address,
            value: (
              <BlockchainWalletSelect
                icon='Wallet'
                topRow={d.address}
                bottomRow={`${d.name} | ${d.type}`}
              />
            ),
            ...d
          }
        })
      : []
  }
  renderFromSelectWalletValue = value => {
    const wallet = this.props.selectBlockchainWalletById(value)
    const type = _.get(wallet, 'type')
    const name = _.get(wallet, 'name')
    return (
      <BlockchainWalletSelect
        icon='Wallet'
        topRow={_.truncate(value, { 'length': 50 })}
        bottomRow={!_.isEmpty(wallet) ? `${name} | ${type}` : null}
      />
    )
  }
  renderFromSelectTokenValue = value => {
    return (
      <TokenSelect
        token={this.props.token}
      />
    )
  }
  renderFromSection () {
    return (
      <FromToContainer>
        <h5>From</h5>
        <StyledSelectInput
          selectProps={{
            label: 'Wallet Address',
            disabled: !!this.state.fromAddress,
            value: this.state.fromAddress,
            valueRenderer: this.renderFromSelectWalletValue
          }}
        />
        {this.state.step === 1 && (
          <div style={{ marginBottom: '40px' }}>
            <StyledSelectInput
              inputProps={{
                label: 'Amount to send',
                value: this.state.fromTokenAmount,
                onChange: this.onChangeAmount('fromToken'),
                type: 'amount',
                maxAmountLength: 18,
                suffix: _.get(this.props.token, 'symbol')
              }}
              selectProps={{
                label: 'Token',
                clearable: false,
                disabled: true,
                value: 'none',
                valueRenderer: this.renderFromSelectTokenValue
              }}
            />
          </div>
        )}
      </FromToContainer>
    )
  }
  renderSettingContent () {
    return (
      <CollapsableContent>
        <Label>Gas Limit</Label>
        <StyledInput
          onChange={e => this.setState({ gasLimit: e.target.value })}
          value={this.state.gasLimit}
          type='number'
          suffix='Units'
        />
        <Label>Gas Price</Label>
        <StyledInput
          onChange={e => this.setState({ gasPrice: e.target.value })}
          value={this.state.gasPrice}
          type='number'
          suffix='Gwei'
          subTitle={`${this.getTransactionFee()} ETH`}
        />
      </CollapsableContent>
    )
  }
  renderToSection () {
    return (
      <FromToContainer>
        <h5>To</h5>
        <StyledSelectInput
          selectProps={{
            label: 'Wallet Address',
            clearable: false,
            disabled: true,
            value: this.props.to,
            valueRenderer: this.renderToSelectWalletValue
          }}
        />
        {this.state.step === 1 && (
          <Collapsable>
            <CollapsableHeader onClick={this.onClickSetting}>
              <span>Settings (Gas limit, Gas price)</span>
              {this.state.settingsOpen ? (
                <Icon name='Chevron-Up' />
              ) : (
                <Icon name='Chevron-Down' />
              )}
            </CollapsableHeader>
            <Accordion path='settings' height={230}>
              {this.state.settingsOpen && this.renderSettingContent()}
            </Accordion>
          </Collapsable>
        )}
        {this.state.step !== 1 && (
          <GrayFeeContainer>
            <span>Amount to send</span>
            <span>
              {this.state.fromTokenAmount}{' '}
              {_.get(this.props.token, 'symbol')}
            </span>
          </GrayFeeContainer>
        )}
        <FeeContainer>
          <span>Transaction fee</span>
          <span>{this.getTransactionFee()} ETH</span>
        </FeeContainer>
      </FromToContainer>
    )
  }
  renderTitle = () => {
    return (
      <Title>
        {this.state.step === 1 && <h4>Import Blockchain Token</h4>}
        {this.state.step === 2 && <h4>Confirm your Transaction</h4>}
        {this.state.step === 3 && (
          <>
            <PendingIcon name='Option-Horizontal' />
            <h4>Pending transaction</h4>
            <div>The transaction is waiting to be included in the block.</div>
            <div>{this.state.txHash}</div>
          </>
        )}
        {this.state.step === 4 && (
          <>
            <SuccessIcon name='Checked' />
            <h4>Successful transaction</h4>
            <div>The transaction was successful.</div>
          </>
        )}
      </Title>
    )
  }
  renderActions () {
    const { txHash } = this.state
    const { network } = this.props
    const exlorerUrl = `${ethExplorerMetamaskNetworkMap[network]}/tx/${txHash}`
    return (
      <>
        {this.state.step === 1 && (
          <ButtonContainer>
            <Button
              size='small'
              onClick={() => this.setState({ step: 2 })}
              disabled={!this.state.fromTokenAmount}
            >
              <span>Transfer</span>
            </Button>
          </ButtonContainer>
        )}
        {this.state.step === 2 && (
          <>
            <ButtonContainer>
              <Button
                size='small'
                type='submit'
                onClick={this.onSubmit}
                loading={this.state.submitting}
              >
                <span>Submit Transaction</span>
              </Button>
              <Button
                size='small'
                styleType='secondary'
                onClick={() => this.setState({ step: 1, error: null })}
              >
                <span>Back to Edit</span>
              </Button>
            </ButtonContainer>
          </>
        )}
        {(this.state.step === 3 || this.state.step === 4) && (
          <ButtonContainer>
            <Button
              size='small'
              styleType='secondary'
              onClick={this.props.onRequestClose}
            >
              <span>Done</span>
            </Button>
            <Links>
              <span>
                <a href={exlorerUrl} target='_blank' rel='noopener noreferrer'>
                  Track on Etherscan <Icon name='Arrow-Right' />
                </a>
              </span>
            </Links>
          </ButtonContainer>
        )}
      </>
    )
  }
  render () {
    return (
      <Form>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        {this.renderTitle()}
        {this.renderFromSection()}
        {this.renderToSection()}
        {this.renderActions()}
        <Error error={this.state.error}>{this.state.error}</Error>
      </Form>
    )
  }
}

const enhance = compose(
  withRouter,
  connect(
    state => ({
      selectCurrentAddress: selectCurrentAddress(state),
      selectBlockchainWalletById: selectBlockchainWalletById(state),
      selectBlockchainWalletBalance: selectBlockchainWalletBalance(state),
      network: selectNetwork(state)
    }),
    {
      transfer,
      getWalletById,
      sendErc20Transaction,
      estimateGasFromTransaction
    }
  )
)

export default enhance(TokenTransferStep)
