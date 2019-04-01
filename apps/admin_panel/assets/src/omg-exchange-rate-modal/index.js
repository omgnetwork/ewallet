import React, { Component, Fragment } from 'react'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import { Input, Button, Icon, Select, Checkbox } from '../omg-uikit'
import Modal from '../omg-modal'
import { createExchangePair } from '../omg-exchange-pair/action'
import { withRouter } from 'react-router-dom'
import TokensFetcher from '../omg-token/tokensFetcher'
import { selectGetTokenById } from '../omg-token/selector'
import TokenSelect from '../omg-token-select'
import { createSearchTokenQuery } from '../omg-token/searchField'
import { formatAmount } from '../utils/formatter'

const Form = styled.form`
  padding: 50px;
  width: 400px;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  input {
    margin-top: 5px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
    padding-left: 40px;
    padding-right: 40px;
  }
  h4 {
    text-align: center;
  }
  h5 {
    padding: 5px 10px;
    background-color: ${props => props.theme.colors.S300};
    display: inline-block;
    margin-top: 40px;
    border-radius: 3px;
  }
`
const InputLabel = styled.div`
  margin-top: 20px;
  font-size: 14px;
  font-weight: 400;
`
const ButtonContainer = styled.div`
  text-align: center;
`
const RateInputContainer = styled.div`
  display: flex;
  > div:first-child {
    flex: 1 1 auto;
    margin-right: 30px;
  }
`
const SyncContainer = styled.div`
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
  height: ${props => (props.show ? 100 : 0)}px;
  opacity: ${props => (props.show ? 1 : 0)};
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

  div {
    padding: 5px 10px;
    background-color: ${props => props.theme.colors.S300};
    color: ${props => props.theme.colors.B300};
    display: inline-block;
    border-radius: 3px;

    :first-child {
      margin-right: 5px;
    }
  }
`

const BackRateContainer = styled.div`
  opacity: ${props => (props.disabled ? 0 : 1)};
  transition: opacity 0.2s ease-in-out;
`

const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({ fromTokenPrefill: selectGetTokenById(state)(props.fromTokenId) }),
    { createExchangePair }
  )
)
class CreateExchangeRateModal extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    fromTokenId: PropTypes.string,
    createExchangePair: PropTypes.func
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  static getDerivedStateFromProps(props, state) {
    if (state.fromTokenId !== props.fromTokenId) {
      return {
        fromTokenSelected: props.fromTokenPrefill,
        fromTokenSearch: props.fromTokenPrefill.name,
        fromTokenSymbol: props.fromTokenPrefill.symbol,
        fromTokenRate: 1,
        fromTokenId: props.fromTokenId
      }
    }
    return null
  }

  state = {
    onlyOneWayExchange: false,
    fromTokenSearch: '',
    fromTokenRate: '',
    fromTokenSymbol: '',
    toTokenRate: '',
    toTokenSearch: '',
    toTokenSymbol: ''
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
  onClickOneWayExchange = e => {
    this.setState(oldState => ({ onlyOneWayExchange: !oldState.onlyOneWayExchange }))
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const result = await this.props.createExchangePair({
        name: this.state.name,
        fromTokenId: _.get(this.state, 'fromTokenSelected.id'),
        toTokenId: _.get(this.state, 'toTokenSelected.id'),
        rate: formatAmount(this.state.toTokenRate, 1) / formatAmount(this.state.fromTokenRate, 1),
        syncOpposite: !this.state.onlyOneWayExchange
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

  get ratesAvailable() {
    return (
      formatAmount(this.state.toTokenRate, 1) > 0 &&
      formatAmount(this.state.fromTokenRate, 1) > 0 &&
      this.state.toTokenSearch &&
      this.state.fromTokenSearch
    )
  }

  renderCalculation = () => {
    if (!this.ratesAvailable) {
      return
    }

    const {
      toTokenRate,
      toTokenSymbol,
      fromTokenRate,
      fromTokenSymbol,
      onlyOneWayExchange
    } = this.state

    const forwardRate = _.round(formatAmount(toTokenRate, 1) / formatAmount(fromTokenRate, 1), 3)
    const backRate = _.round(1 / forwardRate, 3)

    return (
      <>
        <div className="calculation-title">Exchange Pair</div>

        <RateContainer>
          <div>{`1 ${fromTokenSymbol} / ${forwardRate} ${toTokenSymbol}`}</div>
          <BackRateContainer disabled={onlyOneWayExchange}>
            {`1 ${toTokenSymbol} / ${backRate} ${fromTokenSymbol}`}
          </BackRateContainer>
        </RateContainer>

        <div className="calculation-disclaimer">
          {onlyOneWayExchange
            ? `*${fromTokenSymbol} can only be exchanged for ${toTokenSymbol}, and the reverse exchange will not be possible.`
            : `*${fromTokenSymbol} can be exchanged for ${toTokenSymbol} and vice versa.`}
        </div>
      </>
    )
  }

  render() {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name="Close" onClick={this.props.onRequestClose} />
        <h4>Create Exchange Pair</h4>
        <TokensFetcher
          query={createSearchTokenQuery(this.state.fromTokenSearch)}
          render={({ data }) => {
            return (
              <Fragment>
                <h5>From</h5>
                <RateInputContainer>
                  <div>
                    <InputLabel>Token</InputLabel>
                    <Select
                      normalPlaceholder="Token"
                      onSelectItem={this.onSelectTokenSelect('fromToken')}
                      onChange={this.onChangeSearchToken('fromToken')}
                      value={this.state.fromTokenSearch}
                      options={data.map(b => ({
                        key: `${b.id}${b.name}${b.symbol}`,
                        value: <TokenSelect token={b} />,
                        ...b
                      }))}
                    />
                  </div>
                  <div>
                    <InputLabel>Amount</InputLabel>
                    <Input
                      value={this.state.fromTokenRate}
                      onChange={this.onChangeRate('fromToken')}
                      type="amount"
                      normalPlaceholder={0}
                      suffix={this.state.fromTokenSymbol}
                    />
                  </div>
                </RateInputContainer>
              </Fragment>
            )
          }}
        />
        <TokensFetcher
          query={createSearchTokenQuery(this.state.toTokenSearch)}
          render={({ data }) => {
            return (
              <Fragment>
                <h5>To</h5>
                <RateInputContainer>
                  <div>
                    <InputLabel>Token</InputLabel>
                    <Select
                      normalPlaceholder="Token"
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
                  </div>
                  <div>
                    <InputLabel>Amount</InputLabel>
                    <Input
                      value={this.state.toTokenRate}
                      onChange={this.onChangeRate('toToken')}
                      type="amount"
                      step="any"
                      normalPlaceholder={0}
                      suffix={this.state.toTokenSymbol}
                    />
                  </div>
                </RateInputContainer>
                <SyncContainer>
                  <Checkbox
                    label={'Only allow one way exchange'}
                    checked={this.state.onlyOneWayExchange}
                    onClick={this.onClickOneWayExchange}
                  />
                </SyncContainer>
              </Fragment>
            )
          }}
        />

        <CalculationContainer show={this.ratesAvailable}>
          {this.renderCalculation()}
        </CalculationContainer>

        <ButtonContainer>
          <Button size="small" type="submit" loading={this.state.submitting}>
            Create Pair
          </Button>
        </ButtonContainer>
        <Error error={this.state.error}>{this.state.error}</Error>
      </Form>
    )
  }
}

const EnhancedCreateExchange = enhance(CreateExchangeRateModal)

export default class CreateExchangeModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    fromTokenId: PropTypes.string
  }
  render() {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel="create account modal"
      >
        <EnhancedCreateExchange {...this.props} />
      </Modal>
    )
  }
}
