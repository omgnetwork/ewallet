import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Button, Icon, RadioButton, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import { createTransactionRequest } from '../omg-transaction-request/action'
import { connect } from 'react-redux'
import TokensFetcher from '../omg-token/tokensFetcher'
import WalletsFetcher from '../omg-wallet/walletsFetcher'
import { selectPrimaryWalletCurrentAccount } from '../omg-wallet/selector'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
import { formatAmount } from '../utils/formatter'
import moment from 'moment'
import DateTime from 'react-datetime'
import WalletSelect from '../omg-wallet-select'
import TokenSelect from '../omg-token-select'
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
  padding: 70px 0;
  text-align: center;
`
const StyledInput = styled(Input)`
  margin-top: 10px;
`
const StyledSelect = styled(Select)`
  margin-top: 10px;
`
const StyledRadioButton = styled(RadioButton)`
  display: inline-block;
  margin-right: 30px;
  margin-top: 15px;
`
const InputLabelContainer = styled.div`
  display: inline-block;
  width: calc(33.33% - 60px);
  margin: 20px 20px 0 20px;
  text-align: left;
  position: relative;
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
  > span {
    color: ${props => props.theme.colors.S500};
  }
`
const enhance = compose(
  withRouter,
  connect(
    state => ({ primaryWallet: selectPrimaryWalletCurrentAccount(state) }),
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
  state = { selectedToken: {}, onCreateTransactionRequest: _.noop, allowAmountOverride: false }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const result = await this.props.createTransactionRequest({
        ...this.state,
        type: this.state.type ? 'send' : 'receive',
        amount: this.state.amount
          ? formatAmount(this.state.amount, _.get(this.state.selectedToken, 'subunit_to_unit'))
          : null,
        tokenId: _.get(this.state, 'selectedToken.id'),
        address: _.get(this.state, 'selectedWallet.id', this.props.primaryWallet.address),
        accountId: this.props.match.params.accountId,
        expirationDate: this.state.expirationDate
          ? moment(this.state.expirationDate).toISOString()
          : null
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
      console.log(e)
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
  onDateTimeChange = date => {
    this.setState({ expirationDate: date.format('DD/MM/YYYY hh:mm:ss') })
  }
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <InnerContainer>
          <h4>Create Transaction Request</h4>
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
          <InputLabelContainer>
            <InputLabel>
              Correlation Id <span>( Optional )</span>
            </InputLabel>
            <StyledInput
              normalPlaceholder='0x00000000'
              autofocus
              value={this.state.correlationId}
              onChange={this.onChange('correlationId')}
            />
          </InputLabelContainer>
          <InputLabelContainer>
            <InputLabel>
              MaxConsumptions <span>( Optional )</span>
            </InputLabel>
            <StyledInput
              normalPlaceholder='0'
              autofocus
              type='number'
              value={this.state.maxConsumption}
              onChange={this.onChange('maxConsumption')}
            />
          </InputLabelContainer>
          <InputLabelContainer>
            <InputLabel>Token</InputLabel>
            <TokensFetcher
              query={{ page: 1, perPage: 10, search: this.state.searchTokenValue }}
              render={({ individualLoadingStatus, data }) => {
                return (
                  <StyledSelect
                    normalPlaceholder='tk-0x00000000'
                    autofocus
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
          <InputLabelContainer>
            <InputLabel>
              Consumption Lifetime <span>( Optional )</span>
            </InputLabel>
            <StyledInput
              normalPlaceholder='Lifetime of consumption is ms'
              autofocus
              type='number'
              value={this.state.consumptionLifetime}
              onChange={this.onChange('consumptionLifetime')}
            />
          </InputLabelContainer>
          <InputLabelContainer>
            <InputLabel>
              Max Consumption Per User <span>( Optional )</span>
            </InputLabel>
            <StyledInput
              normalPlaceholder='1'
              autofocus
              type='number'
              value={this.state.maxConsumptionPerUser}
              onChange={this.onChange('maxConsumptionPerUser')}
            />
          </InputLabelContainer>
          <InputLabelContainer>
            <InputLabel>
              Wallet Address <span>( Optional )</span>
            </InputLabel>
            <WalletsFetcher
              accountId={this.props.match.params.accountId}
              query={{ search: this.state.address }}
              owned={false}
              render={({ data }) => {
                return (
                  <StyledSelect
                    normalPlaceholder='tk-0x00000000'
                    value={this.state.address}
                    onSelectItem={this.onSelectWallet}
                    onFocus={this.onWalletFocus}
                    onChange={this.onChange('address')}
                    options={data.filter(w => w.identifier !== 'burn').map(wallet => ({
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
            <InputLabel>
              Expiration Date <span>( Optional )</span>
            </InputLabel>
            <DateTime
              onChange={this.onDateTimeChange}
              renderInput={(props, openCalendar, closeCalendar) => {
                return (
                  <StyledInput
                    {...props}
                    normalPlaceholder='Expiry date'
                    value={this.state.expirationDate}
                    onFocus={this.onDateTimeFocus}
                  />
                )
              }}
            />
          </InputLabelContainer>
          <InputLabelContainer>
            <InputLabel>
              Metadata <span>( Optional )</span>
            </InputLabel>
            <StyledInput
              normalPlaceholder='Token name'
              autofocus
              value={this.state.metadata}
              onChange={this.onChange('metadata')}
            />
          </InputLabelContainer>
          <InputLabelContainer>
            <InputLabel>
              Encrypted Metadata <span>( Optional )</span>
            </InputLabel>
            <StyledInput
              normalPlaceholder='meta data'
              autofocus
              value={this.state.encryptedMetadata}
              onChange={this.onChange('encryptedMetadata')}
            />
          </InputLabelContainer>
          <InputLabelContainer>
            <InputLabel>
              Amount <span>( Optional )</span>
            </InputLabel>
            <StyledInput
              normalPlaceholder='1000'
              autofocus
              value={this.state.amount}
              type='number'
              step='any'
              onChange={this.onChange('amount')}
            />
          </InputLabelContainer>
          <ButtonContainer>
            <Button size='small' type='submit' loading={this.state.submitting}>
              Create Request
            </Button>
          </ButtonContainer>
          <Error error={this.state.error}>{this.state.error}</Error>
        </InnerContainer>
        {/* <Datetime /> */}
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
  render = () => {
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
