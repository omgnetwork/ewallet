import React, { Component, Fragment } from 'react'
import { withRouter } from 'react-router-dom'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import numeral from 'numeral'
import { BigNumber } from 'bignumber.js'

import { Input, Button, Icon, Select, Checkbox } from '../omg-uikit'
import { createExchangePair, updateExchangePair } from '../omg-exchange-pair/action'
import TokensFetcher from '../omg-token/tokensFetcher'
import { selectGetTokenById } from '../omg-token/selector'
import TokenSelect from '../omg-token-select'
import { createSearchTokenQuery } from '../omg-token/searchField'
import AllWalletFetcher from '../omg-wallet/allWalletsFetcher'
import WalletSelect from '../omg-wallet-select'
import { createSearchAddressQuery } from '../omg-wallet/searchField'
import { ensureIsNumberOnly } from '../utils/formatter'

const Form = styled.form`
  padding: 50px;
  width: 500px;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
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
  h5 {
    padding: 5px 10px;
    background-color: ${props => props.theme.colors.S300};
    display: inline-block;
    margin-top: 40px;
    border-radius: 2px;
  }
`
const InputLabel = styled.div`
  margin-top: 20px;
  font-size: 14px;
  font-weight: 400;
  span {
    color: ${props => props.theme.colors.S500};
  }
`
const ReadOnlyInput = styled.div`
  padding-top: 7px;
`
const ButtonContainer = styled.div`
  text-align: center;
`
const RateInputContainer = styled.div`
  display: flex;
  > div:first-child {
    flex: 1 1 45%;
    margin-right: 30px;
  }
  > div:nth-child(2) {
    flex: 1 1 55%;
  }
`
const SyncContainer = styled.div`
  margin-top: 20px;
  color: ${props => props.theme.colors.B100};
`
const EndUserExchangeContainer = styled.div`
  margin-top: 20px;
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

const CalculationContainer = styled.div`
  margin-top: 20px;
  transition: all 300ms ease-in-out;
  color: ${props => props.theme.colors.B100};

  .calculation-title {
    padding-bottom: 10px;
  }

  .calculation-disclaimer {
    padding-bottom: 10px;
    font-size: 0.8em;
  }
`

const RateContainer = styled.div`
  display: flex;
  flex-direction: row;
  padding-bottom: 10px;
`

const BackRateContainer = styled.div`
  opacity: ${props => (props.disabled ? 0 : 1)};
  transition: opacity 0.2s ease-in-out;
`

const Rate = styled.div`
  padding: 5px 10px;
  background-color: ${props => props.theme.colors.S300};
  color: ${props => (props.changed ? props.theme.colors.BL300 : props.theme.colors.B300)};
  display: inline-block;
  border-radius: 2px;

  :first-child {
    margin-right: 5px;
  }
`

const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({ fromTokenPrefill: selectGetTokenById(state)(props.fromTokenId) }),
    { createExchangePair, updateExchangePair }
  )
)
class CreateExchangeRateModal extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    fromTokenId: PropTypes.string,
    createExchangePair: PropTypes.func,
    updateExchangePair: PropTypes.func,
    toEdit: PropTypes.object,
    fromTokenPrefill: PropTypes.object
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  static getDerivedStateFromProps (props, state) {
    if (state.fromTokenId !== props.fromTokenId) {
      return {
        editing: !!props.toEdit,
        exchangeId: _.get(props, 'toEdit.id', ''),
        fromTokenSelected: props.fromTokenPrefill,
        fromTokenSearch: props.fromTokenPrefill.name,
        fromTokenSymbol: props.fromTokenPrefill.symbol,
        fromTokenRate: 1,
        fromTokenId: props.fromTokenId,
        toTokenRate: _.get(props, 'toEdit.rate', ''),
        toTokenSelected: _.get(props, 'toEdit.to_token', ''),
        toTokenSearch: _.get(props, 'toEdit.to_token.name', ''),
        toTokenSymbol: _.get(props, 'toEdit.to_token.symbol', ''),
        oppositeExchangePair: _.get(props, 'toEdit.opposite_exchange_pair', null),
        onlyOneWayExchange: !_.get(props, 'toEdit.opposite_exchange_pair', true),
        defaultExchangeAddress: _.get(props, 'toEdit.default_exchange_wallet_address'),
        allowEndUserExchange: _.get(props, 'toEdit.allow_end_user_exchanges', false)
      }
    }
    return null
  }

  state = {
    editing: false,
    exchangeId: '',
    onlyOneWayExchange: false,
    fromTokenSearch: '',
    fromTokenRate: '',
    fromTokenSymbol: '',
    toTokenRate: '',
    toTokenSearch: '',
    toTokenSymbol: '',
    oppositeExchangePair: null
  }

  onChangeName = e => {
    this.setState({ name: e.target.value })
  }
  onChangeRate = type => e => {
    this.setState({ [`${type}Rate`]: e.target.value })
  }
  onChangeSearchToken = type => e => {
    this.setState({
      [`${type}Search`]: e.target.value,
      [`${type}Selected`]: '',
      [`${type}Symbol`]: e.target.value
    })
  }
  onSelectTokenSelect = type => token => {
    this.setState({
      [`${type}Search`]: token.name,
      [`${type}Selected`]: token,
      [`${type}Symbol`]: token.symbol
    })
  }
  onChangeDefaultExchangeAddress = e => {
    this.setState({ defaultExchangeAddress: e.target.value })
  }
  onSelectDefaultExchangeAddress = address => {
    this.setState({ defaultExchangeAddress: address.key })
  }
  onClickOneWayExchange = e => {
    this.setState(oldState => ({ onlyOneWayExchange: !oldState.onlyOneWayExchange }))
  }
  onClickAllowEndUserExchange = () => {
    this.setState(oldState => ({ allowEndUserExchange: !oldState.allowEndUserExchange }))
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    const toRate = ensureIsNumberOnly(this.state.toTokenRate)
    const fromRate = ensureIsNumberOnly(this.state.fromTokenRate)
    try {
      const baseKeys = {
        rate: new BigNumber(toRate).dividedBy(fromRate).toNumber(),
        syncOpposite: !this.state.onlyOneWayExchange
      }
      const result = this.state.editing
        ? await this.props.updateExchangePair({
          ...baseKeys,
          id: this.state.exchangeId,
          defaultExchangeWalletAddress: this.state.defaultExchangeAddress,
          allowEndUserExchanges: this.state.allowEndUserExchange
        })
        : await this.props.createExchangePair({
          ...baseKeys,
          name: this.state.name,
          fromTokenId: _.get(this.state, 'fromTokenSelected.id'),
          toTokenId: _.get(this.state, 'toTokenSelected.id'),
          defaultExchangeWalletAddress: this.state.defaultExchangeAddress,
          allowEndUserExchanges: this.state.allowEndUserExchange
        })
      if (result.data) {
        this.props.onRequestClose()
      } else {
        this.setState({
          submitting: false,
          error: result.error.description || result.error.message
        })
      }
    } catch (e) {
      this.setState({ error: JSON.stringify(e.message), submitting: false })
    }
  }

  getRatesAvailable () {
    return (
      numeral(this.state.toTokenRate).value() > 0 &&
      numeral(this.state.fromTokenRate).value() > 0 &&
      this.state.toTokenSearch &&
      this.state.fromTokenSearch
    )
  }

  renderCalculation = () => {
    const {
      toTokenRate,
      toTokenSymbol,
      fromTokenRate,
      fromTokenSymbol,
      onlyOneWayExchange,
      oppositeExchangePair
    } = this.state
    const fromRateValue = numeral(fromTokenRate).value()
    const toRateValue = numeral(toTokenRate).value()
    const forwardRate = new BigNumber(toRateValue).dividedBy(fromRateValue).toFixed()
    const backRate = new BigNumber(fromRateValue).dividedBy(toRateValue).toFixed()
    const oldForwardRate = _.get(this.props, 'toEdit.rate')
    const forwardRateDiff = String(oldForwardRate) !== forwardRate
    const renderEditingState = () => (
      <>
        <div className='calculation-title'>Exchange Pairs</div>
        <RateContainer>
          <Rate
            changed={forwardRateDiff}
          >{`1 ${fromTokenSymbol} = ${forwardRate} ${toTokenSymbol}`}</Rate>
          {oppositeExchangePair && (
            <BackRateContainer>
              {!forwardRateDiff ? (
                <Rate>{`1 ${toTokenSymbol} = ${
                  oppositeExchangePair.rate
                } ${fromTokenSymbol}`}</Rate>
              ) : !onlyOneWayExchange ? (
                <Rate changed>{`1 ${toTokenSymbol} = ${backRate} ${fromTokenSymbol}`}</Rate>
              ) : (
                <Rate>{`1 ${toTokenSymbol} = ${
                  oppositeExchangePair.rate
                } ${fromTokenSymbol}`}</Rate>
              )}
            </BackRateContainer>
          )}
        </RateContainer>
      </>
    )

    const renderCreationState = () => (
      <>
        <div className='calculation-title'>Exchange Pairs</div>
        <RateContainer>
          <Rate>{`1 ${fromTokenSymbol} = ${forwardRate} ${toTokenSymbol}`}</Rate>
          <BackRateContainer disabled={onlyOneWayExchange}>
            <Rate>{`1 ${toTokenSymbol} = ${backRate} ${fromTokenSymbol}`}</Rate>
          </BackRateContainer>
        </RateContainer>
        <div className='calculation-disclaimer'>
          {onlyOneWayExchange
            ? `*${fromTokenSymbol} can only be exchanged for ${toTokenSymbol}, and the reverse exchange is not possible.`
            : `*${fromTokenSymbol} can be exchanged for ${toTokenSymbol} and vice versa.`}
        </div>
      </>
    )

    return this.state.editing ? renderEditingState() : renderCreationState()
  }

  renderFromForm () {
    return (
      <TokensFetcher
        query={createSearchTokenQuery(this.state.fromTokenSearch)}
        render={({ data }) => {
          return (
            <Fragment>
              <h5>From</h5>
              <RateInputContainer>
                <div>
                  <InputLabel>Token</InputLabel>
                  {this.state.editing && (
                    <ReadOnlyInput>{this.state.fromTokenSearch}</ReadOnlyInput>
                  )}
                  {!this.state.editing && (
                    <Select
                      normalPlaceholder='Token'
                      onSelectItem={this.onSelectTokenSelect('fromToken')}
                      onChange={this.onChangeSearchToken('fromToken')}
                      value={this.state.fromTokenSearch}
                      options={data.map(b => ({
                        key: `${b.id}${b.name}${b.symbol}`,
                        value: <TokenSelect token={b} />,
                        ...b
                      }))}
                    />
                  )}
                </div>
                <div>
                  <InputLabel>Amount</InputLabel>
                  <Input
                    value={this.state.fromTokenRate}
                    onChange={this.onChangeRate('fromToken')}
                    type='amount'
                    normalPlaceholder={0}
                    suffix={this.state.fromTokenSymbol}
                  />
                </div>
              </RateInputContainer>
            </Fragment>
          )
        }}
      />
    )
  }
  renderToForm () {
    return (
      <TokensFetcher
        query={createSearchTokenQuery(this.state.toTokenSearch)}
        render={({ data }) => {
          return (
            <Fragment>
              <h5>To</h5>
              <RateInputContainer>
                <div>
                  <InputLabel>Token</InputLabel>
                  {this.state.editing && <ReadOnlyInput>{this.state.toTokenSearch}</ReadOnlyInput>}
                  {!this.state.editing && (
                    <Select
                      normalPlaceholder='Token'
                      onSelectItem={this.onSelectTokenSelect('toToken')}
                      onChange={this.onChangeSearchToken('toToken')}
                      value={this.state.toTokenSearch}
                      optionBoxHeight={'120px'}
                      options={data.map(b => ({
                        key: `${b.id}${b.name}${b.symbol}`,
                        value: <TokenSelect token={b} />,
                        ...b
                      }))}
                    />
                  )}
                </div>
                <div>
                  <InputLabel>Amount</InputLabel>
                  <Input
                    value={this.state.toTokenRate}
                    onChange={this.onChangeRate('toToken')}
                    type='amount'
                    step='any'
                    normalPlaceholder={0}
                    suffix={this.state.toTokenSymbol}
                  />
                </div>
              </RateInputContainer>
            </Fragment>
          )
        }}
      />
    )
  }

  renderDefaultAddress () {
    return (
      <AllWalletFetcher
        query={createSearchAddressQuery(this.state.defaultExchangeAddress)}
        render={({ data }) => {
          return (
            <>
              <InputLabel>
                Default Exchange Address <span>( Optional )</span>
              </InputLabel>
              <Select
                normalPlaceholder='Exchange Address'
                onSelectItem={this.onSelectDefaultExchangeAddress}
                onChange={this.onChangeDefaultExchangeAddress}
                value={this.state.defaultExchangeAddress}
                optionBoxHeight={'120px'}
                options={data.map(b => ({
                  key: b.address,
                  value: <WalletSelect wallet={b} />
                }))}
              />
            </>
          )
        }}
      />
    )
  }
  renderEndUserExchange () {
    return (
      <EndUserExchangeContainer>
        <Checkbox
          label={'Allow End User Exchange'}
          checked={this.state.allowEndUserExchange}
          onClick={this.onClickAllowEndUserExchange}
        />
      </EndUserExchangeContainer>
    )
  }

  render () {
    const { oppositeExchangePair, editing } = this.state

    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4>{`${editing ? 'Edit' : 'Create'} Exchange Pair`}</h4>
        {this.renderFromForm()}
        {this.renderToForm()}
        {this.getRatesAvailable() && (
          <>
            {!!editing && !!oppositeExchangePair && (
              <SyncContainer>
                {`*The opposite exchange rate of 1 ${oppositeExchangePair.from_token.symbol} 
                = ${_.round(oppositeExchangePair.rate, 3)} ${oppositeExchangePair.to_token.symbol} 
                currently exists. Would you like to sync the opposite rate with the above rates?`}
              </SyncContainer>
            )}

            {(!editing || !!oppositeExchangePair) && (
              <SyncContainer>
                <Checkbox
                  label={editing ? 'Sync opposite' : 'Only allow one way exchange'}
                  checked={editing ? !this.state.onlyOneWayExchange : this.state.onlyOneWayExchange}
                  onClick={this.onClickOneWayExchange}
                />
              </SyncContainer>
            )}

            <CalculationContainer>{this.renderCalculation()}</CalculationContainer>
          </>
        )}
        {this.renderDefaultAddress()}
        {this.renderEndUserExchange()}
        <ButtonContainer>
          <Button
            size='small'
            type='submit'
            loading={this.state.submitting}
            disabled={!this.getRatesAvailable()}
          >
            <span>{this.state.editing ? 'Update Pair' : 'Create Pair'}</span>
          </Button>
        </ButtonContainer>
        <Error error={this.state.error}>{this.state.error}</Error>
      </Form>
    )
  }
}

export default enhance(CreateExchangeRateModal)
