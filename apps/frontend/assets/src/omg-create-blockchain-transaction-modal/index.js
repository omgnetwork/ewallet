import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import web3Utils from 'web3-utils'

import { Button, Icon } from '../omg-uikit'
import Accordion from '../omg-uikit/animation/Accordion'
import Modal from '../omg-modal'
import { transfer } from '../omg-transaction/action'
import { getWalletById } from '../omg-wallet/action'
import { sendTransaction, estimateGasFromTransaction } from '../omg-web3/action'
import { formatAmount } from '../utils/formatter'
import { AllBlockchainWalletsFetcher } from '../omg-blockchain-wallet/blockchainwalletsFetcher'
import BlockchainWalletSelect from '../omg-blockchain-wallet-select'
import { selectBlockchainWalletBalance, selectBlockchainWalletById } from '../omg-blockchain-wallet/selector'
import TokenSelect from '../omg-token-select'
import { selectNetwork } from '../omg-web3/selector'
import { weiToGwei, gweiToWei } from '../omg-web3/web3Utils'
import {
  Form,
  Title,
  PendingIcon,
  SuccessIcon,
  ButtonContainer,
  Error,
  FromToContainer,
  InnerTransferContainer,
  StyledSelectInput,
  StyledInput,
  PasswordInput,
  Label,
  Collapsable,
  FeeContainer,
  GrayFeeContainer,
  CollapsableHeader,
  CollapsableContent,
  Links
} from './styles'
import { ethExplorerMetamaskNetworkMap } from '../omg-web3/constants'

const enhance = compose(
  withRouter,
  connect(
    state => ({
      selectBlockchainWalletById: selectBlockchainWalletById(state),
      selectBlockchainWalletBalance: selectBlockchainWalletBalance(state),
      network: selectNetwork(state)
    }),
    { transfer, getWalletById, sendTransaction, estimateGasFromTransaction }
  )
)
class CreateBlockchainTransaction extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    fromAddress: PropTypes.string,
    selectBlockchainWalletBalance: PropTypes.func,
    selectBlockchainWalletById: PropTypes.func,
    sendTransaction: PropTypes.func,
    estimateGasFromTransaction: PropTypes.func,
    network: PropTypes.number
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  state = {
    fromTokenAmount: '',
    toTokenAmount: '',
    fromAddress: this.props.fromAddress || '',
    toAddress: '',
    settingsOpen: false,
    transactionFee: 0,
    amountToSend: 0,
    step: 1,
    gasLimit: 21000,
    gasPrice: '',
    metaData: '',
    password: '',
    fromTokenSelected: {}
  }
  async componentDidMount () {
    this.setGasPrice()
  }

  async componentDidUpdate (prevProps, prevState) {
    const { toAddress, fromTokenAmount, fromTokenSelected } = this.state
    if (
      fromTokenAmount &&
      toAddress &&
      fromTokenSelected &&
      ((prevState.toAddress !== toAddress) ||
        this.state.fromTokenSelected.id !== prevState.fromTokenSelected.id ||
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
  onSelectTokenSelect = type => token => {
    this.setState({
      [`${type}SearchToken`]:
        _.get(token, 'token.name') || _.get(token, 'name'),
      [`${type}Selected`]: token
    })
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
  onSelectFromAddressSelect = item => {
    if (item) {
      this.setState({
        fromAddress: item.key,
        fromAddressSelect: true,
        fromTokenSelected: this.state.fromTokenSelected
          ? item.balances.find(
            b =>
              b.token.id === _.get(this.state.fromTokenSelected, 'token.id')
          )
          : null
      })
    } else {
      this.setState({
        fromAddress: '',
        fromAddressSelect: false,
        fromTokenSelected: null,
        fromTokenSearchToken: ''
      })
    }
  }
  getTransactionPayload = () => {
    const {
      fromAddress,
      toAddress,
      fromTokenAmount,
      fromTokenSelected,
      gasLimit,
      gasPrice
    } = this.state

    const payload = {
      from: fromAddress,
      to: toAddress,
      value: formatAmount(fromTokenAmount, fromTokenSelected.subunit_to_unit),
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
    this.props.sendTransaction({
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
  renderFromSelectTokenValue = () => {
    const balances = this.props.selectBlockchainWalletBalance(this.state.fromAddress)
    return value => {
      const foundToken = _.find(balances, i => i.token.name === value)
      return foundToken
        ? <TokenSelect balance={foundToken.amount} token={foundToken.token} />
        : value
    }
  }
  renderFromSelectTokenOption = () => {
    const balances = this.props.selectBlockchainWalletBalance(this.state.fromAddress)
    return balances.map(balance => {
      return {
        key: `${balance.token.name}${balance.token.symbol}${balance.token.id}`,
        value: (
          <TokenSelect balance={balance.amount} token={balance.token} />
        ),
        ...balance.token
      }
    })
  }
  renderToSelectWalletValue = data => {
    return value => {
      const wallet = _.find(data, i => i.address === value)
      return wallet ? (
        <BlockchainWalletSelect
          icon='Wallet'
          topRow={wallet.address}
          bottomRow={`${wallet.name} | ${wallet.type}`}
        />
      ) : value
    }
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
        topRow={value}
        bottomRow={!_.isEmpty(wallet) ? `${name} | ${type}` : null}
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
            disabled: !!this.props.fromAddress,
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
                suffix:
                  _.get(this.state.fromTokenSelected, 'token.symbol') ||
                  _.get(this.state.fromTokenSelected, 'symbol')
              }}
              selectProps={{
                label: 'Token',
                clearable: true,
                onSelectItem: this.onSelectTokenSelect('fromToken'),
                value: this.state.fromTokenSearchToken,
                filterByKey: true,
                valueRenderer: this.renderFromSelectTokenValue(),
                options: this.renderFromSelectTokenOption()
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
        <AllBlockchainWalletsFetcher
          render={({ blockchainWallets }) => {
            const hotWallets = blockchainWallets.filter(i => i.type === 'hot')
            return (
              <StyledSelectInput
                selectProps={{
                  label: 'Wallet Address',
                  clearable: true,
                  onSelectItem: this.onSelectToAddressSelect,
                  disabled: this.state.step !== 1,
                  value: this.state.toAddress,
                  valueRenderer: this.renderToSelectWalletValue(hotWallets),
                  options: this.renderToSelectWalletOption(hotWallets)
                }}
              />
            )
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
              {_.get(this.state.fromTokenSelected, 'token.symbol') ||
                _.get(this.state.fromTokenSelected, 'symbol')}
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
        {this.state.step === 1 && <h4>Transfer</h4>}
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
    const { fromAddress, toAddress, fromTokenSelected, txHash } = this.state
    const { network } = this.props
    const exlorerUrl = `${ethExplorerMetamaskNetworkMap[network]}/tx/${txHash}`
    const transferDisabled = !(fromAddress && toAddress && fromTokenSelected)
    return (
      <>
        {this.state.step === 1 && (
          <ButtonContainer>
            <Button
              size='small'
              onClick={() => this.setState({ step: 2 })}
              disabled={transferDisabled}
            >
              <span>Transfer</span>
            </Button>
          </ButtonContainer>
        )}
        {this.state.step === 2 && (
          <>
            {!web3Utils.isAddress(this.state.fromAddress) && (
              <PasswordInput
                placeholder='Enter password to confirm'
                type='password'
                onChange={e => this.setState({ password: e.target.value })}
                value={this.state.password}
              />
            )}
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
        <InnerTransferContainer>
          {this.renderTitle()}
          {this.renderFromSection()}
          {this.renderToSection()}
          {this.renderActions()}
          <Error error={this.state.error}>{this.state.error}</Error>
        </InnerTransferContainer>
      </Form>
    )
  }
}

const EnhancedCreateBlockchainTransaction = enhance(CreateBlockchainTransaction)
export default class CreateBlockchainTransactionModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    onCreateTransaction: PropTypes.func,
    fromAddress: PropTypes.string
  }
  render = () => {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='create blockchain transaction modal'
        overlayClassName='create-blockchain-transaction-modal'
      >
        <EnhancedCreateBlockchainTransaction
          onRequestClose={this.props.onRequestClose}
          onCreateTransaction={this.props.onCreateTransaction}
          fromAddress={this.props.fromAddress}
        />
      </Modal>
    )
  }
}
