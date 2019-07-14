import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import { BigNumber } from 'bignumber.js'
import web3Utils from 'web3-utils'
import { blockchainTokens } from './blockchainTokens'
import { Button, Icon } from '../omg-uikit'
import Accordion from '../omg-uikit/animation/Accordion'
import Modal from '../omg-modal'
import { transfer } from '../omg-transaction/action'
import { getWalletById } from '../omg-wallet/action'
import { formatReceiveAmountToTotal, formatAmount } from '../utils/formatter'
import AllWalletsFetcher from '../omg-wallet/allWalletsFetcher'
import WalletSelect from '../omg-wallet-select'
import { selectWalletById } from '../omg-wallet/selector'
import TokenSelect from '../omg-token-select'
import { createSearchAddressQuery } from '../omg-wallet/searchField'
import { selectBlockchainBalanceByAddress } from '../omg-web3/selector'
import {
  Form,
  Title,
  PendingIcon,
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
const enhance = compose(
  withRouter,
  connect(
    state => ({
      selectWalletById: selectWalletById(state),
      selectBlockchainBalanceByAddress: selectBlockchainBalanceByAddress(state)
    }),
    { transfer, getWalletById }
  )
)
class CreateBlockchainTransaction extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    fromAddress: PropTypes.string,
    selectWalletById: PropTypes.func,
    getWalletById: PropTypes.func,
    match: PropTypes.object,
    onCreateTransaction: PropTypes.func,
    transfer: PropTypes.func,
    selectBlockchainBalanceByAddress: PropTypes.func
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
    gasLimit: '',
    gasPrice: '',
    metaData: '',
    password: ''
  }
  onClickSetting = () => {
    this.setState(oldState => ({ settingsOpen: !oldState.settingsOpen }))
  }
  onChangeInputFromAddress = e => {
    this.setState({
      fromAddress: e.target.value,
      fromTokenSelected: null,
      fromTokenSearchToken: ''
    })
  }
  onChangeInputToAddress = e => {
    this.setState({
      toAddress: e.target.value,
      toTokenSelected: null,
      toTokenSearchToken: ''
    })
  }
  onChangeAmount = type => e => {
    this.setState({ [`${type}Amount`]: e.target.value })
  }
  onChangeSearchToken = type => e => {
    this.setState({
      [`${type}SearchToken`]: e.target.value,
      [`${type}Selected`]: null
    })
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
        toAddressSelect: true,
        toTokenSelected: this.state.toTokenSelected
          ? item.balances.find(
            b => b.token.id === _.get(this.state.toTokenSelected, 'token.id')
          )
          : null
      })
    } else {
      this.setState({
        toAddress: '',
        toAddressSelect: false,
        toTokenSelected: null,
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
  onSubmit = async e => {
    this.setState({ submitting: true })
    e.preventDefault()
    const { fromAddress, toAddress, fromTokenAmount } = this.state
    const { web3 } = window
    web3.eth
      .sendTransaction({
        from: fromAddress,
        to: toAddress,
        value: formatAmount(fromTokenAmount, 10000000000000)
      })
      .on('transactionHash', hash => {
        this.setState({ step: 3, txhash: hash })
      })
      .on('receipt', receipt => {
        console.log(receipt)
      })
      .on('error', () => {
        this.setState({ submitting: false })
      })
    // this.setState({ submitting: true })
    // try {
    //   const fromAmount = formatAmount(
    //     this.state.fromTokenAmount,
    //     _.get(this.state.fromTokenSelected, 'token.subunit_to_unit')
    //   )
    //   const toAmount = formatAmount(
    //     this.state.toTokenAmount,
    //     _.get(this.state.toTokenSelected, 'token.subunit_to_unit')
    //   )
    //   const result = await this.props.transfer({
    //     fromAddress: this.state.fromAddress.trim(),
    //     toAddress: this.state.toAddress.trim(),
    //     fromTokenId: _.get(this.state.fromTokenSelected, 'token.id'),
    //     toTokenId:
    //       _.get(this.state.toTokenSelected, 'token.id') ||
    //       _.get(this.state.fromTokenSelected, 'token.id'),
    //     fromAmount,
    //     toAmount,
    //     exchangeAddress: this.state.exchangeAddress
    //   })
    //   if (result.data) {
    //     this.props.getWalletById(this.state.fromAddress)
    //     this.props.getWalletById(this.state.toAddress)
    //     this.onRequestClose()
    //   } else {
    //     this.setState({
    //       submitting: false,
    //       error: result.error.description || result.error.message
    //     })
    //   }
    //   this.props.onCreateTransaction()
    // } catch (e) {
    //   this.setState({ error: JSON.stringify(e.message) })
    // }
  }
  onRequestClose = () => {
    this.props.onRequestClose()
    this.setState({ submitting: false })
  }
  getBalanceOfSelectedToken = type => {
    return this.state[`${type}Selected`]
      ? formatReceiveAmountToTotal(
        _.get(this.state[`${type}Selected`], 'amount'),
        _.get(this.state[`${type}Selected`], 'token.subunit_to_unit')
      )
      : '-'
  }

  renderFromSelectWalletValue = data => {
    return this.state.fromAddress
      ? value => {
        const wallet = _.find(data, i => i.address === value)
        return wallet ? <WalletSelect wallet={wallet} /> : value
      }
      : null
  }
  renderFromSelectWalletOptions = data => {
    return data
      ? data
        .filter(w => w.identifier !== 'burn')
        .map(d => {
          return {
            key: d.address,
            value: <WalletSelect wallet={d} />,
            ...d
          }
        })
      : []
  }

  renderFromSelectTokenValue = fromWallet => {
    const { fromAddress } = this.state
    const blockchain = web3Utils.isAddress(fromAddress)
    const balances = this.props.selectBlockchainBalanceByAddress(fromAddress)
    return value => {
      const from = blockchain ? blockchainTokens : fromWallet.balances.token

      const foundToken = _.find(
        from,
        token => token.name.toLowerCase() === value.toLowerCase()
      )
      const balance = blockchain
        ? balances[foundToken.symbol].balance
        : foundToken.balance

      return foundToken ? (
        <TokenSelect balance={balance} token={foundToken} />
      ) : (
        value
      )
    }
  }

  renderFromSelectTokenOption = fromWallet => {
    const { fromAddress } = this.state
    if (web3Utils.isAddress(this.state.fromAddress)) {
      const balances = this.props.selectBlockchainBalanceByAddress(fromAddress)
      return blockchainTokens.map(token => ({
        key: `${token.name}${token.symbol}${token.id}`,
        value: (
          <TokenSelect balance={balances[token.symbol].balance} token={token} />
        ),
        ...token
      }))
    }
    return fromWallet
      ? fromWallet.balances.map(b => ({
        key: `${b.token.name}${b.token.symbol}${b.token.id}`,
        value: <TokenSelect balance={b.amount} token={b.token} />,
        ...b
      }))
      : []
  }

  renderToSelectWalletValue = data => {
    const blockchain = web3Utils.isAddress(this.state.toAddress)
    if (blockchain) return value => value
    if (this.state.toAddressSelect) {
      return value => {
        const wallet = _.find(data, i => i.address === value)
        return wallet ? <WalletSelect wallet={wallet} /> : value
      }
    }
    return null
  }

  rendreToSelectWalletOption = data => {
    return data
      ? data.map(d => {
        return {
          key: d.address,
          value: <WalletSelect wallet={d} />,
          ...d
        }
      })
      : []
  }

  renderFromSection () {
    const fromWallet = this.props.selectWalletById(
      this.state.fromAddress.trim()
    )
    return (
      <FromToContainer>
        <h5>From</h5>
        <AllWalletsFetcher
          accountId={this.props.match.params.accountId}
          owned={false}
          query={createSearchAddressQuery(this.state.fromAddress)}
          shouldFetch={
            !!this.props.match.params.accountId ||
            (fromWallet && !!fromWallet.account_id)
          }
          render={({ data }) => {
            return (
              <StyledSelectInput
                selectProps={{
                  label: 'Wallet Address',
                  clearable: true,
                  disabled: !!this.props.fromAddress || this.state.step !== 1,
                  onSelectItem: this.onSelectFromAddressSelect,
                  value: this.state.fromAddress,
                  onChange: this.onChangeInputFromAddress,
                  valueRenderer: this.renderFromSelectWalletValue(data),
                  options: this.renderFromSelectWalletOptions(data)
                }}
              />
            )
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
                onChange: this.onChangeSearchToken('fromToken'),
                value: this.state.fromTokenSearchToken,
                filterByKey: true,
                valueRenderer: this.renderFromSelectTokenValue(fromWallet),
                options: this.renderFromSelectTokenOption(fromWallet)
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
          subTitle={
            this.state.gasPrice
              ? `${new BigNumber(this.state.gasPrice)
                .dividedBy(1000000000)
                .toFixed()} ETH`
              : ''
          }
        />
        <Label>Data</Label>
        <StyledInput
          onChange={e => this.setState({ metaData: e.target.value })}
          value={this.state.metaData}
          subTitle='Optional'
        />
      </CollapsableContent>
    )
  }
  renderToSection () {
    return (
      <FromToContainer>
        <h5>To</h5>
        <AllWalletsFetcher
          query={createSearchAddressQuery(this.state.toAddress)}
          render={({ data }) => {
            return (
              <StyledSelectInput
                selectProps={{
                  label: 'Wallet Address',
                  clearable: true,
                  onSelectItem: this.onSelectToAddressSelect,
                  disabled: this.state.step !== 1,
                  value: this.state.toAddress,
                  onChange: this.onChangeInputToAddress,
                  valueRenderer: this.renderToSelectWalletValue(data),
                  options: this.rendreToSelectWalletOption(data)
                }}
              />
            )
          }}
        />
        {this.state.step === 1 && (
          <Collapsable>
            <CollapsableHeader onClick={this.onClickSetting}>
              <span>Settings (Gas limit, Gas price, Data)</span>
              {this.state.settingsOpen ? (
                <Icon name='Chevron-Up' />
              ) : (
                <Icon name='Chevron-Down' />
              )}
            </CollapsableHeader>
            <Accordion path='settings' height={330}>
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
          <span>{this.state.transactionFee} ETH</span>
        </FeeContainer>
      </FromToContainer>
    )
  }
  renderTitle () {
    return (
      <Title>
        {this.state.step === 1 && <h4>Transfer</h4>}
        {this.state.step === 2 && <h4>Confirm your Transaction</h4>}
        {this.state.step === 3 && (
          <>
            <PendingIcon name='Option-Horizontal' />
            <h4>Pending transaction</h4>
            <div>The transaction is waiting to be included in the block.</div>
          </>
        )}
      </Title>
    )
  }
  renderActions () {
    return (
      <>
        {this.state.step === 1 && (
          <ButtonContainer>
            <Button size='small' onClick={() => this.setState({ step: 2 })}>
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
                onClick={() => this.setState({ step: 1 })}
              >
                <span>Back to Edit</span>
              </Button>
            </ButtonContainer>
          </>
        )}
        {this.state.step === 3 && (
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
                View Transaction <Icon name='Arrow-Right' />
              </span>
              <span>
                Track on Etherscan <Icon name='Arrow-Right' />
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
        overlayClassName='dummy-blockchain-transaction-modal'
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
