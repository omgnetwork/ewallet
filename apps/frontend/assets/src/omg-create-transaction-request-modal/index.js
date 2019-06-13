import React, { Component } from 'react'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import moment from 'moment'
import DateTime from 'react-datetime'
import { compose } from 'recompose'

import { Input, Button, Icon, RadioButton, Select } from '../omg-uikit'
import Accordion from '../omg-uikit/animation/Accordion'
import Modal from '../omg-modal'
import { createTransactionRequest } from '../omg-transaction-request/action'
import TokensFetcher from '../omg-token/tokensFetcher'
import { createSearchTokenQuery } from '../omg-token/searchField'
import WalletsFetcher from '../omg-wallet/allWalletsFetcher'
import { selectPrimaryWalletByAccountId } from '../omg-wallet/selector'
import { formatAmount } from '../utils/formatter'
import WalletSelect from '../omg-wallet-select'
import TokenSelect from '../omg-token-select'
import { createSearchAddressQuery } from '../omg-wallet/searchField'
const Form = styled.form`
  width: 100vw;
  height: 100vh;
  position: relative;
  overflow: scroll;
  > i {
    position: absolute;
    right: 30px;
    top: 30px;
    font-size: 32px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
  }
  h4 {
    text-align: center;
  }
`
const InnerContainer = styled.div`
  max-width: 950px;
  margin: 0 auto;
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  left: 0;
  right: 0;
  @media screen and (max-height: 700px) {
    position: static;
    transform: translateY(0);
    padding: 70px 0;
  }
`
const StyledInput = styled(Input)`
  margin-top: 10px;
`
const StyledSelect = styled(Select)`
  margin-top: 10px;
  width: 100%;
`
const StyledRadioButton = styled(RadioButton)`
  display: inline-block;
  margin-right: 30px;
  margin-top: 15px;
`

const InputLabelContainer = styled.div`
  display: inline-block;
  width: calc(33.33% - 40px);
  margin: 20px 20px 0 20px;
  text-align: left;
  position: relative;
  vertical-align: top;
`

const ButtonContainer = styled.div`
  text-align: center;
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
const InputLabel = styled.div`
  margin-top: 20px;
  font-size: 14px;
  font-weight: 400;
  white-space: nowrap;
  > span {
    color: ${props => props.theme.colors.S500};
    vertical-align: bottom;
  }
`
const RadioSectionContainer = styled.div`
  ${InputLabelContainer} {
    margin-top: 0;
  }
  ${InputLabel} {
    margin-top: 10px;
  }
`
const Collapsable = styled.div`
  background-color: ${props => props.theme.colors.S100};
  text-align: left;
  border-radius: 6px;
  margin-top: 40px;
`
const CollapsableHeader = styled.div`
  cursor: pointer;
  padding: 15px;
  display: flex;
  align-items: center;
  color: ${props => props.theme.colors.S500};
  > i {
    margin-left: auto;
  }
`
const CollapsableContent = styled.div`
  padding-bottom: 50px;
  position: relative;
`
const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({
      primaryWallet: selectPrimaryWalletByAccountId(state)(props.match.params.accountId)
    }),
    { createTransactionRequest }
  )
)

class CreateTransactionRequest extends Component {
  static propTypes = {
    createTransactionRequest: PropTypes.func,
    primaryWallet: PropTypes.object,
    match: PropTypes.object,
    onCreateTransactionRequest: PropTypes.func,
    onRequestClose: PropTypes.func
  }
  static defaultProps = {
    primaryWallet: {}
  }
  state = {
    selectedToken: {},
    onCreateTransactionRequest: _.noop,
    allowAmountOverride: false,
    advanceSettingOpen: false,
    expirationDate: '',
    searchTokenValue: '',
    amount: '',
    consumptionIntervalDuration: '',
    maxConsumption: '',
    consumptionLifetime: '',
    maxConsumptionPerUser: '',
    maxConsumptionPerInterval: '',
    maxConsumptionPerIntervalPerUser: ''
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const result = await this.props.createTransactionRequest({
        ...this.state,
        type: this.state.type ? 'send' : 'receive',
        amount: formatAmount(this.state.amount, _.get(this.state.selectedToken, 'subunit_to_unit')),
        tokenId: _.get(this.state, 'selectedToken.id'),
        address: this.state.address || _.get(this.props, 'primaryWallet.address'),
        accountId:
          _.get(this.state, 'selectedWallet.account_id') ||
          _.get(this.props, 'match.params.accountId'),
        expirationDate: this.state.expirationDate && moment(this.state.expirationDate).toISOString()
      })
      if (result.data) {
        this.props.onRequestClose()
        this.props.onCreateTransactionRequest()
      } else {
        this.setState({
          submitting: false,
          error: result.error.description || result.error.message
        })
      }
    } catch (e) {
      this.setState({ submitting: false })
    }
  }
  onChange = key => e => {
    this.setState({ [key]: e.target.value })
  }
  onWalletFocus = e => {
    this.setState({ address: '', selectedWallet: null })
  }
  onDateTimeFocus = e => {
    this.setState({ expirationDate: '' })
  }
  onRadioChange = key => bool => e => {
    this.setState({ [key]: bool })
  }
  onChangeSearchToken = e => {
    this.setState({ searchTokenValue: e.target.value, selectedToken: {} })
  }
  onSelectTokenSelect = token => {
    this.setState({ searchTokenValue: token.name, selectedToken: token })
  }
  onSelectWallet = wallet => {
    this.setState({ address: wallet.address, selectedWallet: wallet })
  }
  onSelectExchangeWallet = exchangeWallet => {
    this.setState({ exchangeAddress: exchangeWallet.address })
  }
  onDateTimeChange = date => {
    if (date.format) this.setState({ expirationDate: date })
  }
  onClickAdvanceSetting = e => {
    this.setState(oldState => ({ advanceSettingOpen: !oldState.advanceSettingOpen }))
  }
  onBlurExpirationInput = e => {
    this.setState({ expirationModalOpen: false })
  }
  renderRequestType () {
    return (
      <InputLabelContainer>
        <InputLabel>Request Type</InputLabel>
        <StyledRadioButton
          onClick={this.onRadioChange('type')(true)}
          label='Send'
          checked={this.state.type}
        />
        <StyledRadioButton
          onClick={this.onRadioChange('type')(false)}
          label='Receive'
          checked={!this.state.type}
        />
      </InputLabelContainer>
    )
  }
  renderTokenSelect () {
    return (
      <InputLabelContainer>
        <InputLabel>Token</InputLabel>
        <TokensFetcher
          query={{ page: 1, perPage: 10, ...createSearchTokenQuery(this.state.searchTokenValue) }}
          render={({ individualLoadingStatus, data }) => {
            return (
              <StyledSelect
                normalPlaceholder='tk-0x00000000'
                value={this.state.searchTokenValue}
                onSelectItem={this.onSelectTokenSelect}
                onChange={this.onChangeSearchToken}
                options={data.map(b => ({
                  key: `${b.symbol}${b.name}${b.id}`,
                  value: <TokenSelect token={b} />,
                  ...b
                }))}
              />
            )
          }}
        />
      </InputLabelContainer>
    )
  }
  renderTokenAmount () {
    return (
      <InputLabelContainer>
        <InputLabel>
          Amount {this.state.allowAmountOverride && <span>( Optional )</span>}
        </InputLabel>
        <StyledInput
          normalPlaceholder='1000'
          value={this.state.amount}
          type='amount'
          onChange={this.onChange('amount')}
        />
      </InputLabelContainer>
    )
  }
  renderWalletTarget () {
    return (
      <InputLabelContainer>
        <InputLabel>Wallet Address</InputLabel>
        <WalletsFetcher
          query={createSearchAddressQuery(this.state.address)}
          owned={false}
          render={({ data }) => {
            return (
              <StyledSelect
                normalPlaceholder='0x00000000'
                value={this.state.address}
                onSelectItem={this.onSelectWallet}
                onChange={this.onChange('address')}
                options={data
                  .filter(w => w.identifier !== 'burn')
                  .map(wallet => ({
                    key: wallet.address,
                    value: <WalletSelect wallet={wallet} />,
                    ...wallet
                  }))}
              />
            )
          }}
        />
      </InputLabelContainer>
    )
  }
  renderAdvanceSettingContent () {
    return (
      <CollapsableContent>
        <RadioSectionContainer>
          <InputLabelContainer>
            <InputLabel>Require Confirmation</InputLabel>
            <StyledRadioButton
              onClick={this.onRadioChange('requireConfirmation')(false)}
              label='No'
              checked={!this.state.requireConfirmation}
            />
            <StyledRadioButton
              onClick={this.onRadioChange('requireConfirmation')(true)}
              label='Yes'
              checked={this.state.requireConfirmation}
            />
          </InputLabelContainer>
          <InputLabelContainer>
            <InputLabel>Allow Amount Overide</InputLabel>
            <StyledRadioButton
              onClick={this.onRadioChange('allowAmountOverride')(false)}
              label='No'
              checked={!this.state.allowAmountOverride}
            />
            <StyledRadioButton
              onClick={this.onRadioChange('allowAmountOverride')(true)}
              label='Yes'
              checked={this.state.allowAmountOverride}
            />
          </InputLabelContainer>
        </RadioSectionContainer>
        {this.props.match.params.accountId ? this.renderWalletTarget() : null}
        <InputLabelContainer>
          <InputLabel>Correlation ID</InputLabel>
          <StyledInput
            normalPlaceholder='0x00000000'
            value={this.state.correlationId}
            onChange={this.onChange('correlationId')}
          />
        </InputLabelContainer>
        <InputLabelContainer>
          <InputLabel>Max Consumptions</InputLabel>
          <StyledInput
            normalPlaceholder='0'
            type='amount'
            value={this.state.maxConsumption}
            onChange={this.onChange('maxConsumption')}
          />
        </InputLabelContainer>
        <InputLabelContainer>
          <InputLabel>Expiration Date</InputLabel>
          <DateTime
            closeOnSelect
            onChange={this.onDateTimeChange}
            isValidDate={current => current.isAfter(DateTime.moment().subtract(1, 'day'))}
            renderInput={(props, openCalendar, closeCalendar) => {
              return (
                <StyledInput
                  {...props}
                  normalPlaceholder='Expiry date'
                  value={this.state.expirationDate && this.state.expirationDate.format()}
                  onFocus={this.onDateTimeFocus}
                />
              )
            }}
          />
        </InputLabelContainer>
        <InputLabelContainer>
          <InputLabel>Consumption Lifetime (ms)</InputLabel>
          <StyledInput
            normalPlaceholder='Lifetime of consumption in ms'
            type='amount'
            value={this.state.consumptionLifetime}
            onChange={this.onChange('consumptionLifetime')}
          />
        </InputLabelContainer>

        <InputLabelContainer>
          <InputLabel>Consumption Interval Duration (ms)</InputLabel>
          <StyledInput
            type='amount'
            normalPlaceholder='Consumption interval in ms'
            min={0}
            value={this.state.consumptionIntervalDuration}
            onChange={this.onChange('consumptionIntervalDuration')}
          />
        </InputLabelContainer>

        <InputLabelContainer>
          <InputLabel>Max Consumption Per User</InputLabel>
          <StyledInput
            normalPlaceholder='1'
            type='amount'
            value={this.state.maxConsumptionPerUser}
            onChange={this.onChange('maxConsumptionPerUser')}
          />
        </InputLabelContainer>

        <InputLabelContainer>
          <InputLabel>Max Consumption Per Interval</InputLabel>
          <StyledInput
            type='amount'
            normalPlaceholder='10'
            min={0}
            value={this.state.maxConsumptionPerInterval}
            onChange={this.onChange('maxConsumptionPerInterval')}
          />
        </InputLabelContainer>

        <InputLabelContainer>
          <InputLabel>Max Consumption Per Interval Per User</InputLabel>
          <StyledInput
            type='amount'
            normalPlaceholder='10'
            min={0}
            value={this.state.maxConsumptionPerIntervalPerUser}
            onChange={this.onChange('maxConsumptionPerIntervalPerUser')}
          />
        </InputLabelContainer>

        <InputLabelContainer>
          <InputLabel>Exchange Address</InputLabel>
          <WalletsFetcher
            query={createSearchAddressQuery(this.state.exchangeAddress)}
            owned={false}
            render={({ data }) => {
              return (
                <StyledSelect
                  normalPlaceholder='0x00000000'
                  value={this.state.exchangeAddress}
                  onSelectItem={this.onSelectExchangeWallet}
                  onChange={this.onChange('exchangeAddress')}
                  options={data
                    .filter(w => w.identifier !== 'burn')
                    .map(wallet => ({
                      key: wallet.address,
                      value: <WalletSelect wallet={wallet} />,
                      ...wallet
                    }))}
                />
              )
            }}
          />
        </InputLabelContainer>

        <InputLabelContainer>
          <InputLabel>Metadata</InputLabel>
          <StyledInput
            normalPlaceholder='Token name'
            value={this.state.metadata}
            onChange={this.onChange('metadata')}
          />
        </InputLabelContainer>

        <InputLabelContainer>
          <InputLabel>Encrypted Metadata</InputLabel>
          <StyledInput
            normalPlaceholder='meta data'
            value={this.state.encryptedMetadata}
            onChange={this.onChange('encryptedMetadata')}
          />
        </InputLabelContainer>
      </CollapsableContent>
    )
  }
  renderAdvanceOption () {
    return (
      <Collapsable>
        <CollapsableHeader onClick={this.onClickAdvanceSetting}>
          <span>Advanced Settings (Optional)</span>{' '}
          {this.state.advanceSettingOpen ? (
            <Icon name='Chevron-Up' />
          ) : (
            <Icon name='Chevron-Down' />
          )}
        </CollapsableHeader>

        <Accordion path='advanced-settings' height={500}>
          {this.state.advanceSettingOpen && this.renderAdvanceSettingContent()}
        </Accordion>
      </Collapsable>
    )
  }
  renderSubmitButton () {
    return (
      <ButtonContainer>
        <Button size='small' type='submit' loading={this.state.submitting}>
          <span>Create Request</span>
        </Button>
      </ButtonContainer>
    )
  }

  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <InnerContainer>
          <h4>Create Transaction Request</h4>
          {this.renderRequestType()}
          {this.renderTokenSelect()}
          {this.renderTokenAmount()}
          {!this.props.match.params.accountId && this.renderWalletTarget()}
          {this.renderAdvanceOption()}
          {this.renderSubmitButton()}
          <Error error={this.state.error}>{this.state.error}</Error>
        </InnerContainer>
      </Form>
    )
  }
}

const EnhancedCreateTransactionRequest = enhance(CreateTransactionRequest)
export default class CreateTransactionRequestModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    onCreateTransactionRequest: PropTypes.func
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='create account modal'
        overlayClassName='dummy'
      >
        <EnhancedCreateTransactionRequest
          onRequestClose={this.props.onRequestClose}
          onCreateTransactionRequest={this.props.onCreateTransactionRequest}
        />
      </Modal>
    )
  }
}
