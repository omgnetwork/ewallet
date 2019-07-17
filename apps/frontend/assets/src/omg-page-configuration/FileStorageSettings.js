/* eslint-disable react/prop-types */
import React from 'react'
import styled from 'styled-components'

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

const FileStorageSettings = (props) => {
  const renderFileStorageAdpter = (configurations) => {
    return (
      <>
        <h4>File Storage Adapter</h4>
        <Grid>
          <ConfigRow
            name={'File Storage Adapter'}
            description={configurations.file_storage_adapter.description}
            value={props.fileStorageAdapter}
            onSelectItem={props.onSelectFileStorageAdapter}
            type='select'
            options={configurations.file_storage_adapter.options.map(option => ({
              key: option,
              value: option
            }))}
          />
          {props.fileStorageAdapter === 'gcs' && (
            <SubSettingContainer>
              <div>
                <ConfigRow
                  name={'GCS Bucket Key'}
                  description={configurations.gcs_bucket.description}
                  value={props.gcsBucket}
                  placeholder={'ie. google_cloud_1'}
                  onChange={props.onChangeInput('gcsBucket')}
                />
                <ConfigRow
                  name={'GCS Credential JSON'}
                  description={configurations.gcs_credentials.description}
                  value={props.gcsCredentials}
                  placeholder={
                    'ie. {"type": "service_account", "project_id": "your-project-id" ...'
                  }
                  border={props.emailAdapter !== 'gcs'}
                  onChange={props.onChangeInput('gcsCredentials')}
                  inputErrorMessage='Invalid json credential'
                  inputValidator={value => {
                    try {
                      if (value.length === 0) return true
                      // INCASE OF THE GCS KEY HAS NEW LINE IN PEM
                      JSON.parse(value.replace(/\n|\r/g, ''))
                      return true
                    } catch (error) {
                      return false
                    }
                  }}
                />
              </div>
            </SubSettingContainer>
          )}
          {props.fileStorageAdapter === 'aws' && (
            <SubSettingContainer>
              <div>
                <ConfigRow
                  name={'AWS Bucket Name'}
                  description={configurations.aws_bucket.description}
                  value={props.awsBucket}
                  placeholder={'ie. aws_cloud_1'}
                  onChange={props.onChangeInput('awsBucket')}
                />
                <ConfigRow
                  name={'AWS Region'}
                  description={configurations.aws_region.description}
                  value={props.awsRegion}
                  placeholder={'ie. AIzaSyD0g8OombPqMBoIhit8ESNj0TueP_OVx2w'}
                  border={props.emailAdapter !== 'gcs'}
                  onChange={props.onChangeInput('awsRegion')}
                />
                <ConfigRow
                  name={'AWS Access Key ID'}
                  description={configurations.aws_access_key_id.description}
                  value={props.awsAccessKeyId}
                  placeholder={'ie. AIzaSyD0g8OombPqMBoIhit8ESNj0TueP_OVx2w'}
                  border={props.emailAdapter !== 'gcs'}
                  onChange={props.onChangeInput('awsAccessKeyId')}
                />
                <ConfigRow
                  name={'AWS Access Key ID'}
                  description={configurations.aws_secret_access_key.description}
                  value={props.awsSecretAccessKey}
                  placeholder={'ie. AIzaSyD0g8OombPqMBoIhit8ESNj0TueP_OVx2w'}
                  border={props.emailAdapter !== 'gcs'}
                  onChange={props.onChangeInput('awsSecretAccessKey')}
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
          {renderFileStorageAdpter(props.configurations)}
        </form>
      ) : (
        <LoadingSkeletonContainer>
          <LoadingSkeleton width={'150px'} />
          <LoadingSkeleton />
          <LoadingSkeleton />
          <LoadingSkeleton />
        </LoadingSkeletonContainer>
      )}
    </>
  )
}

export default FileStorageSettings
