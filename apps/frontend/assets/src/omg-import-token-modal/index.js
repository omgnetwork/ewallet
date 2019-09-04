import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'

import { selectMetamaskUsable } from '../omg-web3/selector'
import { enableMetamaskEthereumConnection } from '../omg-web3/action'
import { Input, Button, Icon, Banner, Id } from '../omg-uikit'
import Modal from '../omg-modal'
import { getErc20Capabilities, createToken } from '../omg-token/action'
import { formatAmount } from '../utils/formatter'

const Form = styled.form`
  padding: 50px;
  width: 250px;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  input {
    margin-top: 50px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
  }
  h4 {
    text-align: center;
  }
`
const MetaMaskImage = styled.img`
  max-width: 80px;
  display: block;
  margin: 0 auto;
`
const StepStyle = styled(Form)``
const ButtonContainer = styled.div`
  display: flex;
  text-align: center;
  a {
    margin-top: 20px;
    color: white;
    border-radius: 4px;
    border: 1px solid transparent;
    width: '100%';
    min-width: 60px;
    position: relative;
    padding: 10px;
    cursor: pointer;
    background-color: ${props => props.theme.colors.BL400};
  }
  button:first-child {
    margin-right: 10px;
  }
  button:last-child {
    margin-right: 0px;
  }
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
const IdStyle = styled.div`
  text-align: center;
  color: ${props => props.theme.colors.B100};
  margin-bottom: 10px;
`
const InfoIcon = styled(Icon)`
  border-radius: 100%;
  width: 30px;
  min-width: 30px;
  height: 30px;
  background-color: #ffb200;
  color: white;
  font-size: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
`
const ConfirmStyles = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
`
const CancelButton = styled.div`
  cursor: pointer;
  color: ${props => props.theme.colors.BL400};
  margin-top: 20px;
`
const DisclaimerStyle = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  margin-top: 20px;
  button {
    margin: 0;
  }
  em {
    color: ${props => props.theme.colors.B100};
  }
`
class ImportToken extends Component {
  static propTypes = {
    createToken: PropTypes.func,
    getErc20Capabilities: PropTypes.func,
    onFetchSuccess: PropTypes.func,
    onRequestClose: PropTypes.func,
    enableMetamaskEthereumConnection: PropTypes.func,
    metamaskUsable: PropTypes.bool
  }
  state = {
    importedToken: null,
    error: '',
    submitting: false,
    step: 3,
    name: '',
    symbol: '',
    amount: '',
    decimal: 18,
    blockchainAddress: '',
    depositAddress: ''
  }
  componentDidUpdate = prevProps => {
    if (!prevProps.metamaskUsable && this.props.metamaskUsable) {
      this.setState({ step: 5 })
    }
  }
  onChangeInputName = e => {
    this.setState({ name: e.target.value })
  }
  onChangeInputSymbol = e => {
    this.setState({ symbol: e.target.value })
  }
  onChangeDecimal = e => {
    this.setState({ decimal: e.target.value })
  }
  shouldSubmit () {
    return this.state.decimal <= 18 && this.state.name && this.state.symbol
  }
  checkErc20 = async e => {
    e.preventDefault()
    try {
      this.setState({ submitting: true })
      const result = await this.props.getErc20Capabilities(this.state.blockchainAddress)
      if (result.data) {
        this.setState({
          importedToken: result.data,
          submitting: false,
          error: null,
          step: 2,
          name: result.data.name,
          symbol: result.data.symbol,
          amount: result.data.total_supply,
          decimal: result.data.decimals
        })
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
  onCreateToken = async e => {
    // TODO: generate deposit address for master if it doesnt exist already, parallel promise
    e.preventDefault()
    if (this.shouldSubmit()) {
      try {
        this.setState({ submitting: true })
        const result = await this.props.createToken({
          name: this.state.name,
          symbol: this.state.symbol,
          amount: formatAmount(this.state.amount, 10 ** this.state.decimal),
          decimal: this.state.decimal
        })
        if (result.data) {
          this.props.onRequestClose()
          this.props.onFetchSuccess()
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
  }
  goBack = e => {
    e.preventDefault()
    this.setState({
      importedToken: null,
      submitting: false,
      error: null,
      step: 1,
      name: '',
      symbol: '',
      amount: '',
      decimal: ''
    })
  }
  depositToken = e => {
    e.preventDefault()
    if (this.props.metamaskUsable) {
      this.setState({ step: 5 })
    } else {
      this.setState({ step: 4 })
    }
  }
  renderConfirmTokenStep = () => {
    return (
      <StepStyle>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4 style={{ marginBottom: '20px' }}>Import Blockchain Token</h4>
        <ConfirmStyles>
          <InfoIcon name='Info' />
          <div>
            {`In order to confirm the token you have just imported, please deposit some ${this.state.symbol} to ${this.state.depositAddress}`}
          </div>
          <Button
            onClick={this.depositToken}
            size='small'
          >
            <span>Deposit</span>
          </Button>
          <CancelButton onClick={this.props.onRequestClose}>
            Cancel
          </CancelButton>
        </ConfirmStyles>
      </StepStyle>
    )
  }
  renderCreationStep = () => {
    return (
      <Form onSubmit={this.onCreateToken} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4 style={{ marginBottom: '20px' }}>Import Blockchain Token</h4>
        <IdStyle>
          <Id withCopy={false}>{this.state.blockchainAddress}</Id>
        </IdStyle>
        {(!this.state.name || !this.state.symbol || !this.state.decimal) && (
          <Banner text='Please fill in any unspecified fields.' />
        )}
        <Input
          disabled={!!this.state.importedToken.name}
          placeholder='Token name'
          autofocus
          value={this.state.name}
          onChange={this.onChangeInputName}
        />
        <Input
          disabled={!!this.state.importedToken.symbol}
          placeholder='Token symbol'
          value={this.state.symbol}
          onChange={this.onChangeInputSymbol}
        />
        <Input
          disabled={!!this.state.importedToken.decimals}
          placeholder='Decimal point'
          value={this.state.decimal}
          onChange={this.onChangeDecimal}
          error={this.state.decimal > 18}
          errorText={'Decimal point should not exceed 18'}
          type='number'
          step={'1'}
        />
        <ButtonContainer>
          <Button
            size='small'
            styleType='secondary'
            disabled={this.state.submitting}
            onClick={this.goBack}
          >
            <span>Back</span>
          </Button>
          <Button
            size='small'
            type='submit'
            loading={this.state.submitting}
            disabled={!this.shouldSubmit() || this.state.submitting}
          >
            <span>Next</span>
          </Button>
        </ButtonContainer>
        <Error error={this.state.error}>{this.state.error}</Error>
      </Form>
    )
  }
  renderAddressStep = () => {
    return (
      <StepStyle>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4>Import Blockchain Token</h4>
        <Input
          autofocus
          placeholder='Contract Address'
          value={this.state.blockchainAddress}
          onChange={e => this.setState({ blockchainAddress: e.target.value })}
        />
        <ButtonContainer>
          <Button
            size='small'
            loading={this.state.submitting}
            disabled={!this.state.blockchainAddress}
            onClick={this.checkErc20}
          >
            <span>Import</span>
          </Button>
        </ButtonContainer>
        <Error error={this.state.error}>{this.state.error}</Error>
      </StepStyle>
    )
  }
  connectMetamask = e => {
    e.preventDefault()
    this.props.enableMetamaskEthereumConnection()
  }
  renderDownloadMetamask = () => {
    return (
      <StepStyle>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4 style={{ marginBottom: '20px' }}>Import Blockchain Token</h4>
        <MetaMaskImage src={require('../../statics/images/metamask.svg')} />
        <DisclaimerStyle>
          {(window.ethereum || window.web3) && (
            <>
              <Button onClick={this.connectMetamask}>
                Connect Metamask
              </Button>
              <CancelButton onClick={this.props.onRequestClose}>
                Cancel
              </CancelButton>
            </>
          )}
          {(!window.ethereum || !window.web3) && (
            <>
              <span>{'You do not have Metamask'}</span>
              <span><em>{'Please download Metamask to access your wallet.'}</em></span>
              <ButtonContainer>
                <a href='https://metamask.io/' target='_blank' rel='noopener noreferrer'>
                  Download Metamask
                </a>
              </ButtonContainer>
              <CancelButton onClick={this.props.onRequestClose}>
                No, Thanks
              </CancelButton>
            </>
          )}
        </DisclaimerStyle>
      </StepStyle>
    )
  }
  renderTransfer = () => {
    return (
      <div>
        Transfer tokens...
      </div>
    )
  }
  render () {
    switch (this.state.step) {
      case 1:
        return this.renderAddressStep()
      case 2:
        return this.renderCreationStep()
      case 3:
        return this.renderConfirmTokenStep()
      case 4:
        return this.renderDownloadMetamask()
      case 5:
        return this.renderTransfer()
      default:
        return null
    }
  }
}

class ImportTokenModal extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    open: PropTypes.bool,
    createToken: PropTypes.func,
    getErc20Capabilities: PropTypes.func,
    onFetchSuccess: PropTypes.func,
    metamaskUsable: PropTypes.bool,
    enableMetamaskEthereumConnection: PropTypes.func
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='import token modal'
      >
        <ImportToken
          onRequestClose={this.props.onRequestClose}
          createToken={this.props.createToken}
          getErc20Capabilities={this.props.getErc20Capabilities}
          onFetchSuccess={this.props.onFetchSuccess}
          metamaskUsable={this.props.metamaskUsable}
          enableMetamaskEthereumConnection={this.props.enableMetamaskEthereumConnection}
        />
      </Modal>
    )
  }
}
export default connect(
  state => ({
    metamaskUsable: selectMetamaskUsable(state)
  }),
  { createToken, getErc20Capabilities, enableMetamaskEthereumConnection }
)(ImportTokenModal)
