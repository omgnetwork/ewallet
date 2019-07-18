/* eslint-disable react/prop-types */
import React, { useEffect } from 'react'
import styled from 'styled-components'

import { isEmail } from '../utils/validator'
import ConfigRow from './ConfigRow'
import { LoadingSkeleton } from '../omg-uikit'

const LoadingSkeletonContainer = styled.div`
  margin-top: 50px;
  > div {
    margin-bottom: 20px;
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
const Grid = styled.div`
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
`

const EmailSettings = (props) => {
  useEffect(() => {
    return props.handleCancelClick
  }, [])

  const renderEmailSetting = (configurations) => {
    return (
      <>
        <h4>Email Settings</h4>
        <Grid>
          <ConfigRow
            name={'Sender Email'}
            description={configurations.sender_email.description}
            value={props.senderEmail}
            onChange={props.onChangeInput('senderEmail')}
            inputValidator={value => isEmail(value)}
            inputErrorMessage={'Invalid email'}
          />
          <ConfigRow
            name={'Email Adapter'}
            description={configurations.email_adapter.description}
            value={props.emailAdapter}
            onSelectItem={props.onSelectEmailAdapter}
            onChange={props.onChangeInput('emailAdapter')}
            type='select'
            options={configurations.email_adapter.options.map(option => ({
              key: option,
              value: option
            }))}
          />
          {props.emailAdapter === 'smtp' && (
            <SubSettingContainer>
              <div>
                <ConfigRow
                  name={'SMTP Host'}
                  description={configurations.smtp_host.description}
                  value={props.smtpHost}
                  placeholder={'ie. smtp.yourdomain.com'}
                  onChange={props.onChangeInput('smtpHost')}
                />
                <ConfigRow
                  name={'SMTP Port'}
                  description={configurations.smtp_port.description}
                  value={props.smtpPort}
                  placeholder={'ie. 8830'}
                  onChange={props.onChangeInput('smtpPort')}
                />
                <ConfigRow
                  name={'SMTP Username'}
                  description={configurations.smtp_username.description}
                  value={props.smtpUsername}
                  placeholder={'ie. usertest01'}
                  onChange={props.onChangeInput('smtpUsername')}
                />
                <ConfigRow
                  name={'SMTP Password'}
                  description={configurations.smtp_password.description}
                  value={props.smtpPassword}
                  border={props.emailAdapter !== 'smtp'}
                  placeholder={'ie. password'}
                  onChange={props.onChangeInput('smtpPassword')}
                />
              </div>
            </SubSettingContainer>
          )}
        </Grid>
      </>
    )
  }
  return (
    <>
      {!_.isEmpty(props.configurations) ? (
        <form>
          {renderEmailSetting(props.configurations)}
        </form>
      ) : (
        <LoadingSkeletonContainer>
          <LoadingSkeleton width={'150px'} />
          <LoadingSkeleton />
          <LoadingSkeleton />
        </LoadingSkeletonContainer>
      )}
    </>
  )
}

export default EmailSettings
