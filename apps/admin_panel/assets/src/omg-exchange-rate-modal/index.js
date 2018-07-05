import React, { Component, Fragment } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Button, Icon, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import { createExchangePair } from '../omg-exchange-pair/action'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import TokensFetcher from '../omg-token/tokensFetcher'
import { selectGetTokenById } from '../omg-token/selector'
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
  }
  h4 {
    text-align: center;
  }
  h5 {
    padding: 5px 10px;
    background-color: ${props => props.theme.colors.S300};
    display: inline-block;
    margin-top: 20px;
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
const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  text-align: center;
  padding: 10px 0;
  overflow: hidden;
  max-height: ${props => (props.error ? '50px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
`
const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({ fromTokenPrefill: selectGetTokenById(state)(props.fromTokenId)}),
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
  static getDerivedStateFromProps (props, state) {
    if (
      _.get(state, 'fromToken.id') !== props.fromTokenId &&
      props.fromTokenId !== undefined
    ) {
      return {
        fromTokenSelected: props.fromTokenPrefill,
        fromTokenSearch: `${props.fromTokenPrefill.name} (${props.fromTokenPrefill.symbol})`,
        fromTokenRate: 1
      }
    }
    return null
  }
  state = {}
  onChangeName = e => {
    this.setState({ name: e.target.value })
  }
  onChangeRate = type => e => {
    this.setState({ [`${type}Rate`]: e.target.value })
  }
  onChangeSearchToken = type => e => {
    this.setState({ [`${type}Search`]: e.target.value, [`${type}Selected`]: null })
  }
  onSelectTokenSelect = type => token => {
    this.setState({ [`${type}Search`]: token.value, [`${type}Selected`]: token })
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    console.log(this.state)
    try {
      const result = await this.props.createExchangePair({
        name: this.state.name,
        fromTokenId: _.get(this.state, 'fromTokenSelected.id'),
        toTokenId: _.get(this.state, 'toTokenSelected.id'),
        rate: Number(this.state.toTokenRate) / Number(this.state.fromTokenRate)
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
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4>Exchange Rate</h4>
        <InputLabel>Rate Name</InputLabel>
        <Input normalPlaceholder='rate name' onChange={this.onChangeName} value={this.state.name} />

        <TokensFetcher
          render={({ data }) => {
            return (
              <Fragment>
                <h5>From</h5>
                <RateInputContainer>
                  <div>
                    <InputLabel>Token</InputLabel>
                    <Select
                      normalPlaceholder='Token'
                      onSelectItem={this.onSelectTokenSelect('fromToken')}
                      onChange={this.onChangeSearchToken('fromToken')}
                      value={this.state.fromTokenSearch}
                      options={data.map(b => ({
                        ...{
                          key: `${b.id}${b.name}${b.symbol}`,
                          value: `${b.name} (${b.symbol})`
                        },
                        ...b
                      }))}
                    />
                  </div>
                  <div>
                    <InputLabel>Rate</InputLabel>
                    <Input
                      value={this.state.fromTokenRate}
                      onChange={this.onChangeRate('fromToken')}
                      type='number'
                    />
                  </div>
                </RateInputContainer>
                <h5>To</h5>
                <RateInputContainer>
                  <div>
                    <InputLabel>Token</InputLabel>
                    <Select
                      normalPlaceholder='Token'
                      onSelectItem={this.onSelectTokenSelect('toToken')}
                      onChange={this.onChangeSearchToken('toToken')}
                      value={this.state.toTokenSearch}
                      options={data.map(b => ({
                        ...{
                          key: `${b.id}${b.name}${b.symbol}`,
                          value: `${b.name} (${b.symbol})`
                        },
                        ...b
                      }))}
                    />
                  </div>
                  <div>
                    <InputLabel>Rate</InputLabel>
                    <Input
                      value={this.state.toTokenRate}
                      onChange={this.onChangeRate('toToken')}
                      type='number'
                    />
                  </div>
                </RateInputContainer>
              </Fragment>
            )
          }}
        />
        <ButtonContainer>
          <Button size='small' type='submit' loading={this.state.submitting}>
            Create Rate
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
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='create account modal'
      >
        <EnhancedCreateExchange {...this.props} />
      </Modal>
    )
  }
}
