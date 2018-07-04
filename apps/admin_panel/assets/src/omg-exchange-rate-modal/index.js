import React, { Component, Fragment } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Button, Icon, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import { createExchangePair } from '../omg-exchange-pair/action'
import { getWalletById } from '../omg-wallet/action'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import TokensFetcher from '../omg-token/tokensFetcher'
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
    padding:5px 10px;
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
  >div:first-child {
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
    null,
    { createExchangePair }
  )
)
class CreateExchangeRateModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    fromTokenId: PropTypes.string,
    createExchangePair: PropTypes.func
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  state = {}
  // static getDerivedStateFromProps (props, state) {
  //   if (this.state.fromToken.id !== nextProps.fromToken.id && nextProps.fromToken.id !== undefined) {
  //     this.setState({ fromToken.id: nextProps.fromAddress })
  //   }
  //   return null
  // }
  onChangeRate = type => e => {
    this.setState({ [`${type}Amount`]: e.target.value })
  }
  onChangeSearchToken = type => e => {
    this.setState({ [`${type}Search`]: e.target.value })
  }
  onSelectTokenSelect = type => token => {
    this.setState({ [`${type}Search`]: token.value, selectedFromToken: token })
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const result = await this.props.createExchangePair({
        name: this.state.name,
        fromTokenId: this.state.fromAddress,
        toTokenId: this.state.toAddress,
        rate: 0.1
      })
      if (result.data) {
        this.onRequestClose()
      } else {
        this.setState({
          submitting: false,
          error: result.error.description || result.error.message
        })
      }
    } catch (e) {
      this.setState({ error: JSON.stringify(e.message) })
    }
  }
  onRequestClose = () => {
    this.props.onRequestClose()
    this.setState(this.initialState)
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.onRequestClose}
        contentLabel='create account modal'
      >
        <Form onSubmit={this.onSubmit} noValidate>
          <Icon name='Close' onClick={this.props.onRequestClose} />
          <h4>Exchange Rate</h4>
          <InputLabel>Rate Name</InputLabel>
          <Input normalPlaceholder='rate name' />

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
                            key: b.id,
                            value: `${b.id}${b.name}${b.symbol}`
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
      </Modal>
    )
  }
}

export default enhance(CreateExchangeRateModal)
