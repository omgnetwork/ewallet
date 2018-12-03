import React, { Component, Fragment } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import { Button } from '../omg-uikit'
import ConfigurationsFetcher from '../omg-configuration/configurationFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import ConfigRow from './ConfigRow'
import { compose } from 'recompose'
import { connect } from 'react-redux'
import {
  selectConfigurationsByKey,
  selectConfigurationLoadingStatus
} from '../omg-configuration/selector'
import { getConfiguration } from '../omg-configuration/action'
import CONSTANT from '../constants'
const ConfigurationPageContainer = styled.div`
  position: relative;
  padding-bottom: 150px;
  h4 {
    margin-top: 50px;
  }
  button {
    padding-left: 25px;
    padding-right: 25px;
  }
`

const SubSettingContainer = styled.div`
  > div {
    margin-left: 25px;
    padding: 0 20px;
    background-color: ${props => props.theme.colors.S100};
    border-radius: 4px;
    border: 1px solid transparent;
    div:first-child {
      flex: 0 0 175px;
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
    { getConfiguration }
  )
)

class ConfigurationPage extends Component {
  static propTypes = {
    configurations: PropTypes.object,
    configurationLoadingStatus: PropTypes.string
  }

  static getDerivedStateFromProps (props, state) {
    if (!state.fetched && props.configurationLoadingStatus === CONSTANT.LOADING_STATUS.SUCCESS) {
      return {
        baseUrl: props.configurations.base_url.value,
        redirectUrlPrefixes: props.configurations.redirect_url_prefixes.value,
        enableStandalone: props.configurations.enable_standalone.value,
        maxPerPage: props.configurations.max_per_page.value,
        minPasswordLength: props.configurations.min_password_length.value,
        senderEmail: props.configurations.sender_email.value,
        emailAdapter: props.configurations.email_adapter.value,
        smtpHost: props.configurations.smtp_host.value,
        smtpPort: props.configurations.smtp_port.value,
        smtpUsername: props.configurations.smtp_username.value,
        smtpPassword: props.configurations.smtp_password.value,
        fileStorageAdapter: props.configurations.file_storage_adapter.value,
        gcsBucket: props.configurations.gcs_bucket.value,
        gcsCredentials: props.configurations.gcs_credentials.value,
        awsBucket: props.configurations.aws_bucket.value,
        awsRegion: props.configurations.aws_region.value,
        awsAccessKeyId: props.configurations.aws_access_key_id.value,
        awsSecretAccessKey: props.configurations.aws_secret_access_key.value,
        balanceCachingStrategy: props.configurations.balance_caching_strategy.value,
        fetched: true
      }
    } else {
      return null
    }
  }

  state = {}
  onSelectEmailAdapter = option => {
    this.setState({ emailAdapter: option.value })
  }
  onSelectFileStorageAdapter = option => {
    this.setState({ fileStorageAdapter: option.value })
  }
  onChangeInput = key => e => {
    this.setState({ [key]: e.target.value })
  }

  renderSaveButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateAccount} key={'save'}>
        <span>Save Configuration</span>
      </Button>
    )
  }

  renderFileStorageAdpter (configurations) {
    return (
      <Fragment>
        <h4>File Storage Adapter</h4>
        <ConfigRow
          name={configurations.file_storage_adapter.key}
          description={configurations.file_storage_adapter.description}
          value={this.state.fileStorageAdapter}
          onSelectItem={this.onSelectFileStorageAdapter}
          type='select'
          options={configurations.file_storage_adapter.options.map(option => ({
            key: option,
            value: option
          }))}
        />
        {this.state.fileStorageAdapter === 'gcs' && (
          <SubSettingContainer>
            <div>
              <ConfigRow
                name={configurations.gcs_bucket.key}
                description={configurations.gcs_bucket.description}
                value={this.state.gcsBucket}
                placeholder={'ie. google_cloud_1'}
                onChange={this.onChangeInput('gcsBucket')}
              />
              <ConfigRow
                name={configurations.gcs_credentials.key}
                description={configurations.gcs_credentials.description}
                value={configurations.gcs_credentials.value}
                placeholder={'ie. AIzaSyD0g8OombPqMBoIhit8ESNj0TueP_OVx2w'}
                border={this.state.emailAdapter !== 'gcs'}
              />
            </div>
          </SubSettingContainer>
        )}
        {this.state.fileStorageAdapter === 'aws' && (
          <SubSettingContainer>
            <div>
              <ConfigRow
                name={configurations.aws_bucket.key}
                description={configurations.aws_bucket.description}
                value={this.state.awsBucket}
                placeholder={'ie. aws_bucket_1'}
                onChange={this.onChangeInput('awsBucket')}
              />
              <ConfigRow
                name={configurations.aws_region.key}
                description={configurations.aws_region.description}
                value={this.state.awsRegion}
                placeholder={'ie. us-east-1'}
                onChange={this.onChangeInput('awsRegion')}
              />
              <ConfigRow
                name={configurations.aws_access_key_id.key}
                description={configurations.aws_access_key_id.description}
                value={this.state.awsAccessKeyId}
                placeholder={'ie. AKIAIOSFODNN7EXAMPLE'}
                onChange={this.onChangeInput('awsAccessKeyId')}
              />
              <ConfigRow
                name={configurations.aws_secret_access_key.key}
                description={configurations.aws_secret_access_key.description}
                value={this.state.awsSecretAccessKey}
                border={this.state.emailAdapter !== 'aws'}
                placeholder={'ie. wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'}
                onChange={this.onChangeInput('awsSecretAccessKey')}
              />
            </div>
          </SubSettingContainer>
        )}
      </Fragment>
    )
  }
  renderCacheSetting (configurations) {
    return (
      <Fragment>
        <h4>Cache Setting</h4>
        <ConfigRow
          name={configurations.balance_caching_strategy.key}
          description={configurations.balance_caching_strategy.description}
          value={this.state.balanceCachingStrategy}
          onSelectItem={this.onSelectFileStorageAdapter}
          type='select'
          options={configurations.balance_caching_strategy.options.map(option => ({
            key: option,
            value: option
          }))}
        />
      </Fragment>
    )
  }
  renderGlobalSetting (configurations) {
    return (
      <Fragment>
        <h4>Global Setting</h4>
        <ConfigRow
          name={configurations.base_url.key}
          description={configurations.base_url.description}
          value={this.state.baseUrl}
          onChange={this.onChangeInput('baseUrl')}
        />
        <ConfigRow
          name={configurations.redirect_url_prefixes.key}
          description={configurations.redirect_url_prefixes.description}
          value={this.state.redirectUrlPrefixes}
          onChange={this.onChangeInput('redirectUrlPrefixes')}
        />
        <ConfigRow
          name={configurations.enable_standalone.key}
          description={configurations.enable_standalone.description}
          value={this.state.enableStandalone}
          onChange={this.onChangeInput('enableStandalone')}
        />
        <ConfigRow
          name={configurations.max_per_page.key}
          description={configurations.max_per_page.description}
          value={this.state.maxPerPage}
          inputType='number'
          onChange={this.onChangeInput('maxPerPage')}
        />
        <ConfigRow
          name={configurations.min_password_length.key}
          description={configurations.min_password_length.description}
          value={this.state.minPasswordLength}
          onChange={this.onChangeInput('minPasswordLength')}
        />
      </Fragment>
    )
  }
  renderEmailSetting (configurations) {
    return (
      <Fragment>
        <h4>Email Setting</h4>
        <ConfigRow
          name={configurations.sender_email.key}
          description={configurations.sender_email.description}
          value={this.state.senderEmail}
          onChange={this.onChangeInput('senderEmail')}
        />
        <ConfigRow
          name={configurations.email_adapter.key}
          description={configurations.email_adapter.description}
          value={this.state.emailAdapter}
          onSelectItem={this.onSelectEmailAdapter}
          onChange={this.onChangeInput('emailAdapter')}
          type='select'
          options={configurations.email_adapter.options.map(option => ({
            key: option,
            value: option
          }))}
        />
        {this.state.emailAdapter === 'smtp' && (
          <SubSettingContainer>
            <div>
              <ConfigRow
                name={configurations.smtp_host.key}
                description={configurations.smtp_host.description}
                value={this.state.smtpHost}
                placeholder={'ie. smtp.yourdomain.com'}
                onChange={this.onChangeInput('smtpHost')}
              />
              <ConfigRow
                name={configurations.smtp_port.key}
                description={configurations.smtp_port.description}
                value={this.state.smtpPort}
                placeholder={'ie. 8830'}
                onChange={this.onChangeInput('smtpPort')}
              />
              <ConfigRow
                name={configurations.smtp_username.key}
                description={configurations.smtp_username.description}
                value={this.state.smtpUsername}
                placeholder={'ie. usertest01'}
                onChange={this.onChangeInput('smtpUsername')}
              />
              <ConfigRow
                name={configurations.smtp_password.key}
                description={configurations.smtp_password.description}
                value={this.state.smtpPassword}
                border={this.state.emailAdapter !== 'smtp'}
                placeholder={'ie. password'}
                onChange={this.onChangeInput('smtpPassword')}
              />
            </div>
          </SubSettingContainer>
        )}
      </Fragment>
    )
  }
  renderConfigurationPage = ({ data: configurations }) => {
    return (
      <ConfigurationPageContainer>
        <TopNavigation
          title={'Configuration'}
          buttons={[this.renderSaveButton()]}
          secondaryAction={false}
          types={false}
        />
        {!_.isEmpty(this.props.configurations) && (
          <div>
            {this.renderGlobalSetting(this.props.configurations)}
            {this.renderEmailSetting(this.props.configurations)}
            {this.renderFileStorageAdpter(this.props.configurations)}
            {this.renderCacheSetting(this.props.configurations)}
          </div>
        )}
      </ConfigurationPageContainer>
    )
  }

  render () {
    return <ConfigurationsFetcher render={this.renderConfigurationPage} {...this.state} />
  }
}

export default enhance(ConfigurationPage)
