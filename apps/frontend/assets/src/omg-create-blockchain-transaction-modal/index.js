import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import { BigNumber } from 'bignumber.js'

import { Button, Icon, SelectInput, Input } from '../omg-uikit'
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

const Form = styled.div`
  width: 100vw;
  height: 100vh;
  position: relative;
  > i {
    position: absolute;
    right: 30px;
    top: 30px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
    font-size: 30px;
  }
  input {
    margin-top: 5px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
  }
  h4 {
    font-size: 18px;
  }
`
const Title = styled.div`
  margin-bottom: 20px;
`
const PendingIcon = styled(Icon)`
  color: white;
  background-color: orange;
  width: 30px;
  height: 30px;
  margin-bottom: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 100%;
`
const ButtonContainer = styled.div`
  display: flex;
  flex-direction: row;
  justify-content: space-between;
`
const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  text-align: center;
  padding: 10px 0;
  overflow: hidden;
  max-height: ${props => (props.error ? '100px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
`
const FromToContainer = styled.div`
  h5 {
    letter-spacing: 1px;
    background-color: ${props => props.theme.colors.S300};
    display: inline-block;
    padding: 5px 10px;
    border-radius: 2px;
  }
`
const InnerTransferContainer = styled.div`
  max-width: 600px;
  padding: 50px;
  margin: 0 auto;
`
const StyledSelectInput = styled(SelectInput)`
  margin-bottom: 10px;
`
const StyledInput = styled(Input)`
  margin-bottom: 20px;
`
const PasswordInput = styled(Input)`
  margin-top: 40px;
`
const Label = styled.div`
  color: ${props => props.theme.colors.S400};
`
const Collapsable = styled.div`
  background-color: ${props => props.theme.colors.S100};
  text-align: left;
  border-radius: 6px;
  border: 1px solid ${props => props.theme.colors.S400};
  margin-top: 20px;
`
const FeeContainer = styled.div`
  padding: 10px;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  border-radius: 6px;
  i[name='Info'] {
    color: ${props => props.theme.colors.S400};
    margin-left: 5px;
    cursor: pointer;
  }
`
const GrayFeeContainer = styled(FeeContainer)`
  background-color: ${props => props.theme.colors.S200};
`
const CollapsableHeader = styled.div`
  cursor: pointer;
  padding: 10px 20px;
  display: flex;
  align-items: center;
  color: ${props => props.theme.colors.S500};
  > i {
    margin-left: auto;
  }
`
const CollapsableContent = styled.div`
  padding: 40px;
  border-radius: 6px;
  background-color: white;
  display: flex;
  flex-direction: column;
  height: 100%;
`
const Links = styled.div`
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  justify-content: flex-end;
  color: ${props => props.theme.colors.B100};
  span {
    margin-top: 5px;
    cursor: pointer;
  }
  i[name='Arrow-Right'] {
    margin-left: 5px;
  }
`
const enhance = compose(
  withRouter,
  connect(
    state => ({ selectWalletById: selectWalletById(state) }),
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
    transfer: PropTypes.func
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
  onClickSetting = e => {
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
    this.setState({ [`${type}SearchToken`]: e.target.value, [`${type}Selected`]: null })
  }
  onSelectTokenSelect = type => token => {
    this.setState({
      [`${type}SearchToken`]: _.get(token, 'token.name'),
      [`${type}Selected`]: token
    })
  }
  onSelectToAddressSelect = item => {
    if (item) {
      this.setState({
        toAddress: item.key,
        toAddressSelect: true,
        toTokenSelected: this.state.toTokenSelected
          ? item.balances.find(b => b.token.id === _.get(this.state.toTokenSelected, 'token.id'))
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
          ? item.balances.find(b => b.token.id === _.get(this.state.fromTokenSelected, 'token.id'))
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
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const fromAmount = formatAmount(
        this.state.fromTokenAmount,
        _.get(this.state.fromTokenSelected, 'token.subunit_to_unit')
      )
      const toAmount = formatAmount(
        this.state.toTokenAmount,
        _.get(this.state.toTokenSelected, 'token.subunit_to_unit')
      )
      const result = await this.props.transfer({
        fromAddress: this.state.fromAddress.trim(),
        toAddress: this.state.toAddress.trim(),
        fromTokenId: _.get(this.state.fromTokenSelected, 'token.id'),
        toTokenId:
          _.get(this.state.toTokenSelected, 'token.id') ||
          _.get(this.state.fromTokenSelected, 'token.id'),
        fromAmount,
        toAmount,
        exchangeAddress: this.state.exchangeAddress
      })
      if (result.data) {
        this.props.getWalletById(this.state.fromAddress)
        this.props.getWalletById(this.state.toAddress)
        this.onRequestClose()
      } else {
        this.setState({
          submitting: false,
          error: result.error.description || result.error.message
        })
      }
      this.props.onCreateTransaction()
    } catch (e) {
      this.setState({ error: JSON.stringify(e.message) })
    }
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

  renderFromSection () {
    const fromWallet = this.props.selectWalletById(this.state.fromAddress.trim())
    return (
      <FromToContainer>
        <h5>From</h5>
        <AllWalletsFetcher
          accountId={this.props.match.params.accountId}
          owned={false}
          query={createSearchAddressQuery(this.state.fromAddress)}
          shouldFetch={!!this.props.match.params.accountId || (fromWallet && !!fromWallet.account_id)}
          render={({ data }) => {
            return (
              <StyledSelectInput
                selectProps={{
                  label: 'Wallet Address',
                  clearable: true,
                  disabled: !!this.props.fromAddress,
                  onSelectItem: this.onSelectFromAddressSelect,
                  value: this.state.fromAddress,
                  onChange: this.onChangeInputFromAddress,
                  valueRenderer: this.state.fromAddress
                    ? value => {
                      const wallet = _.find(data, i => i.address === value)
                      return wallet
                        ? <WalletSelect wallet={wallet} />
                        : value
                    }
                    : null,
                  options:
                    data
                      ? data.filter(w => w.identifier !== 'burn')
                        .map(d => {
                          return {
                            key: d.address,
                            value: <WalletSelect wallet={d} />,
                            ...d
                          }
                        })
                      : []
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
                suffix: _.get(this.state.fromTokenSelected, 'token.symbol')
              }}
              selectProps={{
                label: 'Token',
                clearable: true,
                onSelectItem: this.onSelectTokenSelect('fromToken'),
                onChange: this.onChangeSearchToken('fromToken'),
                value: this.state.fromTokenSearchToken,
                filterByKey: true,
                valueRenderer: this.state.fromTokenSelected
                  ? value => {
                    const found = _.find(
                      fromWallet.balances,
                      b => b.token.name.toLowerCase() === value.toLowerCase()
                    )
                    return found
                      ? <TokenSelect balance={found.amount} token={found.token} />
                      : value
                  }
                  : null,
                options:
                  fromWallet
                    ? fromWallet.balances.map(b => ({
                      key: `${b.token.name}${b.token.symbol}${b.token.id}`,
                      value: <TokenSelect balance={b.amount} token={b.token} />,
                      ...b
                    }))
                    : []
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
          subTitle={this.state.gasPrice ? `${new BigNumber(this.state.gasPrice).dividedBy(1000000000).toFixed()} ETH` : ''}
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
                  value: this.state.toAddress,
                  onChange: this.onChangeInputToAddress,
                  valueRenderer: this.state.toAddressSelect
                    ? value => {
                      const wallet = _.find(data, i => i.address === value)
                      return wallet
                        ? <WalletSelect wallet={wallet} />
                        : value
                    }
                    : null,
                  options:
                    data
                      ? data.map(d => {
                        return {
                          key: d.address,
                          value: <WalletSelect wallet={d} />,
                          ...d
                        }
                      })
                      : []
                }}
              />
            )
          }}
        />
        {this.state.step === 1 && (
          <Collapsable>
            <CollapsableHeader onClick={this.onClickSetting}>
              <span>Settings (Gas limit, Gas price, Data)</span>
              {this.state.settingsOpen
                ? <Icon name='Chevron-Up' />
                : <Icon name='Chevron-Down' />}
            </CollapsableHeader>
            <Accordion path='settings' height={330}>
              {this.state.settingsOpen && this.renderSettingContent()}
            </Accordion>
          </Collapsable>
        )}
        {this.state.step !== 1 && (
          <GrayFeeContainer>
            <span>Amount to send</span>
            <span>{this.state.fromTokenAmount} {_.get(this.state.fromTokenSelected, 'token.symbol')}</span>
          </GrayFeeContainer>
        )}
        <FeeContainer>
          <span>Transaction fee <Icon name='Info' /></span>
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
            <PasswordInput
              placeholder='Enter password to confirm'
              type='password'
              onChange={e => this.setState({ password: e.target.value })}
              value={this.state.password}
            />
            <ButtonContainer>
              <Button size='small' onClick={() => this.setState({ step: 3 })}>
                <span>Submit Transaction</span>
              </Button>
              <Button size='small' styleType='secondary' onClick={() => this.setState({ step: 1 })}>
                <span>Back to Edit</span>
              </Button>
            </ButtonContainer>
          </>
        )}
        {this.state.step === 3 && (
          <ButtonContainer>
            <Button size='small' styleType='secondary' onClick={this.props.onRequestClose}>
              <span>Back to Hot Wallet</span>
            </Button>
            <Links>
              <span>View Transaction <Icon name='Arrow-Right' /></span>
              <span>Track on Etherscan <Icon name='Arrow-Right' /></span>
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
