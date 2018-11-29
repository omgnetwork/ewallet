import React, { Component, Fragment } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import ConfigurationsFetcher from '../omg-configuration/configurationFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import queryString from 'query-string'
import ConfigRow from './ConfigRow'

const ConfigurationPageContainer = styled.div`
  position: relative;
  padding-bottom: 150px;
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
class ConfigurationPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object
  }
  state = {
    emailAdapter: ''
  }

  onSelectEmailAdapter = option => {
    this.setState({ emailAdapter: option.value })
  }
  onSelectFileStorageAdapter = option => {
    this.setState({ fileStorageAdapter: option.value })
  }

  getConfiguration (configurations) {
    configurations.forEach(config => {
      if (config.parent) {
      }
    })
  }

  renderFileStorageAdpter (configurations) {
    return (
      <Fragment>
        <h4 style={{ marginTop: '40px' }}>File Storage Adapter</h4>
        <ConfigRow
          name={configurations.file_storage_adapter.key}
          description={configurations.file_storage_adapter.description}
          value={this.state.fileStorageAdapter || configurations.file_storage_adapter.value}
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
                value={configurations.gcs_bucket.value}
                placeholder={'ie. google_cloud_1'}
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
                value={configurations.aws_bucket.value}
                placeholder={'ie. aws_bucket_1'}
              />
              <ConfigRow
                name={configurations.aws_region.key}
                description={configurations.aws_region.description}
                value={configurations.aws_region.value}
                placeholder={'ie. us-east-1'}
              />
              <ConfigRow
                name={configurations.aws_access_key_id.key}
                description={configurations.aws_access_key_id.description}
                value={configurations.aws_access_key_id.value}
                placeholder={'ie. AKIAIOSFODNN7EXAMPLE'}
              />
              <ConfigRow
                name={configurations.aws_secret_access_key.key}
                description={configurations.aws_secret_access_key.description}
                value={configurations.aws_secret_access_key.value}
                border={this.state.emailAdapter !== 'aws'}
                placeholder={'ie. wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'}
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
        <h4 style={{ marginTop: '40px' }}>Cache Setting</h4>
        <ConfigRow
          name={configurations.balance_caching_strategy.key}
          description={configurations.balance_caching_strategy.description}
          value={this.state.balanceCache || configurations.balance_caching_strategy.value}
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
          value={configurations.base_url.value}
        />
        <ConfigRow
          name={configurations.redirect_url_prefixes.key}
          description={configurations.redirect_url_prefixes.description}
          value={configurations.redirect_url_prefixes.value}
        />
        <ConfigRow
          name={configurations.enable_standalone.key}
          description={configurations.enable_standalone.description}
          value={configurations.enable_standalone.value}
        />
        <ConfigRow
          name={configurations.max_per_page.key}
          description={configurations.max_per_page.description}
          value={configurations.max_per_page.value}
        />
        <ConfigRow
          name={configurations.min_password_length.key}
          description={configurations.min_password_length.description}
          value={configurations.min_password_length.value}
        />
      </Fragment>
    )
  }
  renderEmailSetting (configurations) {
    return (
      <Fragment>
        <h4 style={{ marginTop: '40px' }}>Email Setting</h4>
        <ConfigRow
          name={configurations.sender_email.key}
          description={configurations.sender_email.description}
          value={configurations.sender_email.value}
        />
        <ConfigRow
          name={configurations.email_adapter.key}
          description={configurations.email_adapter.description}
          value={this.state.emailAdapter || configurations.email_adapter.value}
          onSelectItem={this.onSelectEmailAdapter}
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
                value={configurations.smtp_host.value}
                placeholder={'ie. smtp.yourdomain.com'}
              />
              <ConfigRow
                name={configurations.smtp_port.key}
                description={configurations.smtp_port.description}
                value={configurations.smtp_port.value}
                placeholder={'ie. 8830'}
              />
              <ConfigRow
                name={configurations.smtp_username.key}
                description={configurations.smtp_username.description}
                value={configurations.smtp_username.value}
                placeholder={'ie. usertest01'}
              />
              <ConfigRow
                name={configurations.smtp_password.key}
                description={configurations.smtp_password.description}
                value={configurations.smtp_password.value}
                border={this.state.emailAdapter !== 'smtp'}
                placeholder={'ie. password'}
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
          buttons={null}
          secondaryAction={false}
          types={false}
        />
        {!_.isEmpty(configurations) && (
          <div>
            {this.renderGlobalSetting(configurations)}
            {this.renderEmailSetting(configurations)}
            {this.renderFileStorageAdpter(configurations)}
            {this.renderCacheSetting(configurations)}
          </div>
        )}
      </ConfigurationPageContainer>
    )
  }

  render () {
    return (
      <ConfigurationsFetcher
        render={this.renderConfigurationPage}
        {...this.state}
        {...this.props}
        query={{
          page: queryString.parse(this.props.location.search).page
        }}
      />
    )
  }
}

export default withRouter(ConfigurationPage)
