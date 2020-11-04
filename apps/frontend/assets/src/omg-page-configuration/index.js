import React from 'react'
import { Prompt, withRouter, NavLink, Route, Switch } from 'react-router-dom'
import { compose } from 'recompose'
import { connect } from 'react-redux'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import _ from 'lodash'

import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button, Icon } from '../omg-uikit'
import ConfigurationsFetcher from '../omg-configuration/configurationFetcher'
import {
  selectConfigurationsByKey,
  selectConfigurationLoadingStatus
} from '../omg-configuration/selector'
import {
  getConfiguration,
  updateConfiguration
} from '../omg-configuration/action'
import CONSTANT from '../constants'

import BlockchainSettings from './BlockchainSettings'
import CacheSettings from './CacheSettings'
import EmailSettings from './EmailSettings'
import FileStorageSettings from './FileStorageSettings'
import GlobalSettings from './GlobalSettings'

const ConfigurationPageContainer = styled.div`
  position: relative;
  padding-bottom: 150px;
  h4:not(:first-child) {
    margin-top: 50px;
  }
`
const ConnectionNotification = styled.div`
  margin: 40px 0;
  background-color: ${props => props.connected ? props.theme.colors.S100 : '#fef7e5'};
  padding: 10px 24px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  i[name="Info"] {
    margin-right: 10px;
    color: ${props => props.connected ? props.theme.colors.S100 : '#ffb200'};
  }
`
const Layout = styled.div`
  display: flex;
  flex-direction: row;
`
const SideMenu = styled.div`
  display: flex;
  flex-direction: column;
  width: 200px;
  margin-right: 40px;
  a {
    margin-bottom: 15px;
    color: black;
  }
  .active {
    color: ${props => props.theme.colors.BL400};
  }
`
const Content = styled.div`
width: 100%;
  form {
    width: 100%;
    h4 {
      margin-bottom: 10px;
    }
  }
`
const enhance = compose(
  withRouter,
  connect(
    state => {
      return {
        configurations: selectConfigurationsByKey(state),
        configurationLoadingStatus: selectConfigurationLoadingStatus(state)
      }
    },
    { getConfiguration, updateConfiguration }
  )
)

class ConfigurationPage extends React.Component {
  static propTypes = {
    configurations: PropTypes.object,
    configurationLoadingStatus: PropTypes.string,
    updateConfiguration: PropTypes.func,
    divider: PropTypes.bool,
    location: PropTypes.object,
    history: PropTypes.object
  }
  static getDerivedStateFromProps = (props, state) => {
    const config = props.configurations
    if (
      !state.fetched &&
      props.configurationLoadingStatus === CONSTANT.LOADING_STATUS.SUCCESS
    ) {
      const derivedState = {
        baseUrl: config.base_url.value,
        redirectUrlPrefixes: config.redirect_url_prefixes.value,
        enableStandalone: config.enable_standalone.value,
        enableBlockchain: config.blockchain_enabled.value,
        maxPerPage: config.max_per_page.value,
        minPasswordLength: config.min_password_length.value,
        senderEmail: config.sender_email.value,
        emailAdapter: config.email_adapter.value,
        smtpHost: config.smtp_host.value,
        smtpPort: config.smtp_port.value,
        smtpUsername: config.smtp_username.value,
        smtpPassword: config.smtp_password.value,
        fileStorageAdapter: config.file_storage_adapter.value,
        gcsBucket: config.gcs_bucket.value,
        gcsCredentials: config.gcs_credentials.value,
        awsBucket: config.aws_bucket.value,
        awsRegion: config.aws_region.value,
        awsAccessKeyId: config.aws_access_key_id.value,
        awsSecretAccessKey: config.aws_secret_access_key.value,
        balanceCachingStrategy: config.balance_caching_strategy.value,
        balanceCachingResetFrequency:
          config.balance_caching_reset_frequency.value,
        forgetPasswordRequestLifetime:
          config.forget_password_request_lifetime.value,
        masterAccount: config.master_account.value,
        preAuthTokenLifetime: config.pre_auth_token_lifetime.value,
        authTokenLifetime: config.auth_token_lifetime.value,
        fetched: true,
        blockchainEnabled: config.blockchain_enabled.value,
        blockchainConfirmationsThreshold: config.blockchain_confirmations_threshold.value,
        blockchainDepositPoolingInterval: config.blockchain_deposit_pooling_interval.value,
        blockchainPollInterval: config.blockchain_poll_interval.value,
        blockchainStateSaveInterval: config.blockchain_state_save_interval.value,
        blockchainSyncInterval: config.blockchain_sync_interval.value, 
        blockchainTransactionPollInterval: config.blockchain_transaction_poll_interval.value,
      }
      return {
        originalState: derivedState,
        ...derivedState
      }
    }
    return null
  }
  state = {
    originalState: null,
    submitStatus: CONSTANT.LOADING_STATUS.DEFAULT
  }
  componentDidMount = () => {
    if (this.props.location.pathname === '/configuration') {
      this.props.history.push('/configuration/global_settings')
    }
  }
  handleCancelClick = () => {
    this.setState(oldState => ({
      originalState: oldState.originalState,
      submitStatus: CONSTANT.LOADING_STATUS.DEFAULT,
      ...oldState.originalState
    }))
  }
  resetGcsState = () => {
    this.setState({
      gcsBucket: this.props.configurations.gcs_bucket.value,
      gcsCredentials: this.props.configurations.gcs_credentials.value
    })
  }
  resetAwsState = () => {
    this.setState({
      awsBucket: this.props.configurations.aws_bucket.value,
      awsRegion: this.props.configurations.aws_region.value,
      awsAccessKeyId: this.props.configurations.aws_access_key_id.value,
      awsSecretAccessKey: this.props.configurations.aws_secret_access_key.value
    })
  }
  isSendButtonDisabled = () => {
    return (
      Object.keys(this.props.configurations)
        .filter(configKey => this.state[_.camelCase(configKey)] !== undefined)
        .reduce((prev, curr) => {
          const stateValue = this.state[_.camelCase(curr)]
          const propsValue = this.props.configurations[curr].value
          return prev && String(propsValue) === String(stateValue)
        }, true) ||
      Number(this.state.maxPerPage) < 1 ||
      Number(this.state.minPasswordLength) < 1 ||
      !this.state.masterAccount
    )
  }
  isAddPrefixButtonDisabled = () => {
    const lastDynamicInputPrefix = _.last(this.state.redirectUrlPrefixes)
    return lastDynamicInputPrefix && lastDynamicInputPrefix.length <= 0
  }
  onSelectEmailAdapter = option => {
    this.setState({ emailAdapter: option.value })
  }
  onSelectBalanceCache = option => {
    this.setState({ balanceCachingStrategy: option.value })
  }
  onSelectMasterAccount = option => {
    this.setState({
      masterAccount: option.id,
      masterAccountSelected: true
    })
  }
  onClickRemovePrefix = index => e => {
    if (this.state.redirectUrlPrefixes.length > 1) {
      const newState = this.state.redirectUrlPrefixes.slice()
      newState.splice(index, 1)
      this.setState({
        redirectUrlPrefixes: newState
      })
    }
  }
  onSelectFileStorageAdapter = option => {
    switch (option.value) {
      case 'aws':
        this.resetGcsState()
        break
      case 'gcs':
        this.resetAwsState()
        break
      default:
        this.resetAwsState()
        this.resetGcsState()
    }
    this.setState({ fileStorageAdapter: option.value })
  }
  onChangeInput = key => e => {
    let newState = { [key]: e.target.value }
    if (key === 'masterAccount') {
      newState = {
        ...newState,
        masterAccountSelected: false
      }
    }

    this.setState(newState)
  }
  onChangeInputredirectUrlPrefixes = index => e => {
    const newState = this.state.redirectUrlPrefixes.slice()
    newState[index] = e.target.value
    this.setState({
      redirectUrlPrefixes: newState
    })
  }
  onChangeEnableStandalone = e => {
    this.setState(oldState => ({
      enableStandalone: !oldState.enableStandalone
    }))
  }
  onChangeEnableBlockchain = e => {
    this.setState(oldState => ({
      enableBlockchain: !oldState.enableBlockchain
    }))
  }
  onClickSaveConfiguration = async e => {
    try {
      this.setState({ submitStatus: CONSTANT.LOADING_STATUS.PENDING })
      const omittedUnchange = _.omitBy(this.state, (value, key) => {
        const configObject = this.props.configurations[_.snakeCase(key)]
        const stateValue = this.state[key]
        if (configObject) {
          return _.isEqual(configObject.value, stateValue)
        }
        return true
      })

      const result = await this.props.updateConfiguration(omittedUnchange)
      if (result.data) {
        const updatedState = _.omitBy(
          {
            submitStatus: CONSTANT.LOADING_STATUS.SUCCESS,
            baseUrl: _.get(result.data.data, 'base_url.value'),
            redirectUrlPrefixes: _.get(
              result.data.data,
              'redirect_url_prefixes.value'
            ),
            enableStandalone: _.get(
              result.data.data,
              'enable_standalone.value'
            ),
            enableBlockchain: _.get(
              result.data.data,
              'enable_blockchain.value'
            ),
            maxPerPage: _.get(result.data.data, 'max_per_page.value'),
            minPasswordLength: _.get(
              result.data.data,
              'min_password_length.value'
            ),
            senderEmail: _.get(result.data.data, 'sender_email.value'),
            emailAdapter: _.get(result.data.data, 'email_adapter.value'),
            smtpHost: _.get(result.data.data, 'smtp_host.value'),
            smtpPort: _.get(result.data.data, 'smtp_port.value'),
            smtpUsername: _.get(result.data.data, 'smtp_username.value'),
            smtpPassword: _.get(result.data.data, 'smtp_password.value'),
            fileStorageAdapter: _.get(
              result.data.data,
              'file_storage_adapter.value'
            ),
            gcsBucket: _.get(result.data.data, 'gcs_bucket.value'),
            gcsCredentials: _.get(result.data.data, 'gcs_credentials.value'),
            awsBucket: _.get(result.data.data, 'aws_bucket.value'),
            awsRegion: _.get(result.data.data, 'aws_region.value'),
            awsAccessKeyId: _.get(result.data.data, 'aws_access_key_id.value'),
            awsSecretAccessKey: _.get(
              result.data.data,
              'aws_secret_access_key.value'
            ),
            balanceCachingStrategy: _.get(
              result.data.data,
              'balance_caching_strategy.value'
            ),
            balanceCachingResetFrequency: _.get(
              result.data.data,
              'balance_caching_reset_frequency.value'
            ),
            masterAccount: _.get(result.data.data, 'master_account.value'),
            authTokenLifetime: _.get(
              result.data.data,
              'auth_token_lifetime.value'
            ),
            preAuthTokenLifetime: _.get(
              result.data.data,
              'pre_auth_token_lifetime.value'
            )
          },
          _.isNil
        )
        this.setState(updatedState)

        setTimeout(() => {
          window.location.reload()
        }, 1500)
      } else {
        this.setState({ submitStatus: CONSTANT.LOADING_STATUS.FAILED })
      }
    } catch (error) {
      this.setState({ submitStatus: CONSTANT.LOADING_STATUS.FAILED })
    }
  }
  onClickAddPrefix = e => {
    if (!this.isAddPrefixButtonDisabled()) {
      this.setState(oldState => {
        return { redirectUrlPrefixes: [...oldState.redirectUrlPrefixes, ''] }
      })
    }
  }
  renderCancelButton = () => {
    return (
      <Button
        size='small'
        onClick={this.handleCancelClick}
        key='cancel'
        styleType='secondary'
        disabled={this.isSendButtonDisabled()}
      >
        <span>Cancel</span>
      </Button>
    )
  }
  renderSaveButton = () => {
    return (
      <Button
        size='small'
        onClick={this.onClickSaveConfiguration}
        key='save'
        loading={this.state.submitStatus === CONSTANT.LOADING_STATUS.PENDING}
        disabled={this.isSendButtonDisabled()}
      >
        <span>Save</span>
      </Button>
    )
  }
  configApi = {
    resetGcsState: this.resetGcsState,
    resetAwsState: this.resetAwsState,
    isAddPrefixButtonDisabled: this.isAddPrefixButtonDisabled,
    onSelectEmailAdapter: this.onSelectEmailAdapter,
    onSelectBalanceCache: this.onSelectBalanceCache,
    onSelectMasterAccount: this.onSelectMasterAccount,
    onClickRemovePrefix: this.onClickRemovePrefix,
    onSelectFileStorageAdapter: this.onSelectFileStorageAdapter,
    onChangeInput: this.onChangeInput,
    onChangeInputredirectUrlPrefixes: this.onChangeInputredirectUrlPrefixes,
    onChangeEnableStandalone: this.onChangeEnableStandalone,
    onChangeEnableBlockchain: this.onChangeEnableBlockchain,
    onClickAddPrefix: this.onClickAddPrefix,
    handleCancelClick: this.handleCancelClick
  }
  renderConfigurationPage = () => {
    return (
      <ConfigurationPageContainer>
        <TopNavigation
          divider={this.props.divider}
          title={'Configuration'}
          searchBar={false}
          buttons={[
            this.renderCancelButton(),
            this.renderSaveButton()
          ]}
          types={false}
        />
        <ConnectionNotification connected={_.get(this.props.configurations, 'enable_blockchain.value', false)}>
          <Icon name='Info' />
          {`The app is currently ${_.get(this.props.configurations, 'enable_blockchain.value', false) ? '' : ' not'} connected to Ethereum.`}
        </ConnectionNotification>
        <Layout>
          <SideMenu>
            <NavLink to='/configuration/blockchain_settings'>Blockchain Settings</NavLink>
            <NavLink to='/configuration/global_settings'>Global Settings</NavLink>
            <NavLink to='/configuration/email_settings'>Email Settings</NavLink>
            <NavLink to='/configuration/cache_settings'>Cache Settings</NavLink>
            <NavLink to='/configuration/file_storage_settings'>File Storage Settings</NavLink>
          </SideMenu>
          <Content>
            <Switch>
              <Route
                exact
                path='/configuration/blockchain_settings'
                render={() => (
                  <BlockchainSettings
                    {...this.props}
                    {...this.state}
                    {...this.configApi}
                  />
                )}
              />
              <Route
                exact
                path='/configuration/global_settings'
                render={() => (
                  <GlobalSettings
                    {...this.props}
                    {...this.state}
                    {...this.configApi}
                  />
                )}
              />
              <Route
                exact
                path='/configuration/email_settings'
                render={() => (
                  <EmailSettings
                    {...this.props}
                    {...this.state}
                    {...this.configApi}
                  />
                )}
              />
              <Route
                exact
                path='/configuration/cache_settings'
                render={() => (
                  <CacheSettings
                    {...this.props}
                    {...this.state}
                    {...this.configApi}
                  />
                )}
              />
              <Route
                exact
                path='/configuration/file_storage_settings'
                render={() => (
                  <FileStorageSettings
                    {...this.props}
                    {...this.state}
                    {...this.configApi}
                  />
                )}
              />
            </Switch>
          </Content>
        </Layout>
      </ConfigurationPageContainer>
    )
  }
  render () {
    return (
      <>
        <Prompt
          when={!this.isSendButtonDisabled()}
          message='You have unsaved changes. Are you sure you want to leave?'
        />
        <ConfigurationsFetcher
          render={this.renderConfigurationPage}
          {...this.state}
        />
      </>
    )
  }
}

export default enhance(ConfigurationPage)
