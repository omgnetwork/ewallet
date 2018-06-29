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
import {withRouter} from 'react-router-dom'
const Form = styled.form`
  width: 100vw;
  height: 100vh;
  position: relative;
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
  padding: 100px 0;
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
`
const ButtonContainer = styled.div`
  text-align: center;
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
const InputLabel = styled.div`
  margin-top: 20px;
  font-size: 14px;
  font-weight: 400;
  > span {
    color: ${props => props.theme.colors.S500};
  }
`

class CreateTokenModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    createTransactionRequest: PropTypes.func,
    primaryWallet: PropTypes.object,
    match: PropTypes.object
  }
  state = { selectedToken: {} }
  onRequestClose = () => {
    this.setState({})
    this.props.onRequestClose()
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const result = await this.props.createTransactionRequest({
        ...this.state,
        type: this.state.type ? 'send' : 'receive',
        amount: this.state.amount * _.get(this.state.selectedToken, 'subunit_to_unit'),
        tokenId: this.state.selectedToken.id,
        address: this.state.address || this.props.primaryWallet.address
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
      this.setState({ submitting: false, error: e })
    }
  }
  onChange = key => e => {
    this.setState({ [key]: e.target.value })
  }
  onRadioChange = key => bool => e => {
    this.setState({ [key]: bool })
  }
  onChangeSearchToken = e => {
    this.setState({ searchTokenValue: e.target.value, selectedToken: {} })
  }
  onSelectTokenSelect = token => {
    this.setState({ searchTokenValue: token.value, selectedToken: token })
  }

  render = () => {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.onRequestClose}
        contentLabel='create account modal'
        overlayClassName='fuck'
      >
        <Form onSubmit={this.onSubmit} noValidate>
          <Icon name='Close' onClick={this.onRequestClose} />
          <InnerContainer>
            <h4>Create Transaction Request</h4>
            <InputLabelContainer>
              <InputLabel>
                Request Type <span>( Optional )</span>
              </InputLabel>
              <StyledRadioButton
                onClick={this.onRadioChange('type')(true)}
                label='Send'
                checked={this.state.type}
              />
              <StyledRadioButton
                onClick={this.onRadioChange('type')(false)}
                label='Recieve'
                checked={!this.state.type}
              />
            </InputLabelContainer>
            <InputLabelContainer>
              <InputLabel>
                Require Confirmation <span>( Optional )</span>
              </InputLabel>
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
              <InputLabel>
                Allow Amount Overide <span>( Optional )</span>
              </InputLabel>
              <StyledRadioButton
                onClick={this.onRadioChange('allowAmountOveride')(false)}
                label='No'
                checked={!this.state.allowAmountOveride}
              />
              <StyledRadioButton
                onClick={this.onRadioChange('allowAmountOveride')(true)}
                label='Yes'
                checked={this.state.allowAmountOveride}
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
                render={({ individualLoadingStatus, data }) => {
                  return (
                    <StyledSelect
                      normalPlaceholder='tk-0x00000000'
                      autofocus
                      value={this.state.selectedToken.name}
                      onSelectItem={this.onSelectTokenSelect}
                      onChange={this.onChangeSearchToken}
                      options={
                        individualLoadingStatus === 'SUCCESS'
                          ? data.map(b => ({
                            ...{
                              key: b.id,
                              value: `${b.name} (${b.symbol})`
                            },
                            ...b
                          }))
                          : []
                      }
                    />
                  )
                }}
                query={{ page: 1, perPage: 10, search: this.state.tokenId }}
              />
            </InputLabelContainer>
            <InputLabelContainer>
              <InputLabel>
                Consumption Lifetime <span>( Optional )</span>
              </InputLabel>
              <StyledInput
                normalPlaceholder=''
                autofocus
                type='number'
                value={this.state.expirationDate}
                onChange={this.onChange('expirationDate')}
              />
            </InputLabelContainer>
            <InputLabelContainer>
              <InputLabel>
                Max consumption per user <span>( Optional )</span>
              </InputLabel>
              <StyledInput
                normalPlaceholder='Token name'
                autofocus
                type='number'
                value={this.state.maxConsumptionPerUser}
                onChange={this.onChange('maxConsumptionPerUser')}
              />
            </InputLabelContainer>
            <InputLabelContainer>
              <InputLabel>
                Wallet address <span>( Optional )</span>
              </InputLabel>
              <WalletsFetcher
                accountId={this.props.match.params.accountId}
                render={() => {
                  return (
                    <StyledInput
                      normalPlaceholder='0x00000000'
                      autofocus
                      value={this.state.address}
                      onChange={this.onChange('address')}
                    />
                  )
                }}
              />
            </InputLabelContainer>
            <InputLabelContainer>
              <InputLabel>
                Expiration Date <span>( Optional )</span>
              </InputLabel>
              <StyledInput
                normalPlaceholder='Token name'
                autofocus
                value={this.state.expirationDate}
                onChange={this.onChange('expirationDate')}
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
        </Form>
      </Modal>
    )
  }
}

export default withRouter(connect(
  state => ({ primaryWallet: selectPrimaryWalletCurrentAccount(state) }),
  { createTransactionRequest }
)(CreateTokenModal))
