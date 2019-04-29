import React, { Component, PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import queryString from 'query-string'
import moment from 'moment'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
import DateTime from 'react-datetime'
import { connect } from 'react-redux'

import { Input, Button, Icon, Tag } from '../omg-uikit'
import SortableTable from '../omg-table'
import ExportFetcher from '../omg-export/exportFetcher'
import { downloadExportFileById, getExports } from '../omg-export/action'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { exportTransaction } from '../omg-transaction/action'
import { createSearchTransactionExportQuery } from './searchField'
import CONSTANT from '../constants'
import ProgressBar from './ProgressBar'
import ConfirmationModal from '../omg-confirmation-modal'
import { MarkContainer } from '../omg-page-transaction'

const Container = styled.div`
  position: relative;
  padding-bottom: 50px;
`
const FormDetailContainer = styled.form`
  border: 1px solid #ebeff7;
  border-radius: 2px;
  padding: 30px;
  box-shadow: 0 4px 12px 0 #e8eaed;
  margin-bottom: 40px;
  .date-time {
    margin-top: 30px;
    margin-right: 20px;
    :last-child {
      margin-right: 0;
    }
  }
  input {
    width: 100%;
  }
  > div:first-child {
    margin-bottom: 20px;
  }
  h5 {
    text-align: left;
  }
  .row {
    display: flex;
    flex-direction: row;
  }
`
const TimestampContainer = styled.div`
  display: flex;
  align-items: center;
  > span {
    flex: 1 1 auto;
    margin-right: 5px;
    white-space: nowrap;
  }
  i {
    margin-left: auto;
    padding: 5px;
    border: 1px solid ${props => props.theme.colors.S400};
    border-radius: 4px;
    color: ${props => (props.disabled ? props.theme.colors.S400 : props.theme.colors.B400)};
    :hover {
      background-color: ${props => props.theme.colors.BL400};
      color: white;
    }
  }
`
const ProgressTextContainer = styled.div`
  display: flex;
  margin-bottom: 5px;
  font-size: 12px;
  > span:first-child {
    flex: 1 1 auto;
  }
  > span:last-child {
    margin-left: auto;
  }
`

const ContentContainer = styled.div`
  margin-top: 40px;
  display: flex;
  flex-direction: row;
`

const ActionContainer = styled.div`
  flex: 1 1 0;
  margin-right: 40px;

  .title {
    font-weight: bold;
    margin-bottom: 40px;
  }
`

const TableContainer = styled.div`
  flex: 1.2 1 0;
  td:nth-child(2) {
    width: 190px;
  }
  td {
    height: 50px;
    a:hover {
      text-decoration: underline;
    }
  }
  td:first-child {
    width: 300px;
    > * {
      white-space: nowrap;
      text-overflow: ellipsis;
      overflow: hidden;
      width: 300px;
      display: inline-block;
    }
  }
  .string-value {
    white-space: nowrap;
  }
`

const AlertEmptyTextContainer = styled.div`
  max-width: 500px;
  font-size: 14px;
  > div:nth-child(2) {
    margin: 20px 0;
  }
  span {
    color: red;
  }
`

const TitleContainer = styled.div`
  span {
    padding-left: 10px;
  }
  > i {
    cursor: pointer;
  }
`
const StatusContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i {
    color: white;
    font-size: 10px;
  }
`

const columns = [
  { key: 'filename', title: 'NAME' },
  { key: 'params_match_all', title: 'MATCH ALL' },
  { key: 'params_match_any', title: 'MATCH ANY' },
  { key: 'status', title: 'STATUS' },
  { key: 'created_at', title: 'EXPORTED AT' }
]

const enhance = compose(
  withRouter,
  connect(
    null,
    {
      exportTransaction,
      downloadExportFileById,
      getExports
    }
  )
)
class TransactionExportPage extends Component {
  static propTypes = {
    history: PropTypes.object,
    exportTransaction: PropTypes.func,
    location: PropTypes.object,
    downloadExportFileById: PropTypes.func,
    getExports: PropTypes.func,
    divider: PropTypes.bool
  }
  state = {
    submitStatus: CONSTANT.LOADING_STATUS.DEFAULT,
    confirmationModalOpen: false,
    fromTime: '',
    toTime: '',
    fromTimeFocus: false,
    toTimeFocus: false,
    fromDate: '',
    toDate: '',
    fromDateFocus: false,
    toDateFocus: false
  }

  componentDidMount = () => {
    this._pollingExport = setInterval(() => {
      this.props.getExports({
        page: queryString.parse(this.props.location.search)['page'],
        perPage: 10
      })
    }, 3000)
  }

  componentWillUnmount () {
    clearInterval(this._pollingExport)
  }

  onDateFromChange = date => {
    if (date.format) this.setState({ fromDate: date })
  }
  onDateFromFocus = e => {
    this.setState({ fromDate: '', fromDateFocus: true })
  }
  onDateToChange = date => {
    if (date.format) this.setState({ toDate: date })
  }
  onDateToFocus = e => {
    this.setState({ toDate: '', toDateFocus: true })
  }
  onTimeFromChange = time => {
    if (time.format) this.setState({ fromTime: time })
  }
  onTimeFromFocus = e => {
    this.setState({ fromTime: '', fromTimeFocus: true })
  }
  onTimeToChange = time => {
    if (time.format) this.setState({ toTime: time })
  }
  onTimeToFocus = e => {
    this.setState({ toTime: '', toTimeFocus: true })
  }
  onClickExport = (fetch, confirm) => async e => {
    e.preventDefault()
    if (!this.state.fromDate && !this.state.toDate && !confirm) {
      this.setState({ confirmationModalOpen: true })
    } else {
      this.setState({ submitStatus: CONSTANT.LOADING_STATUS.PENDING, confirmationModalOpen: false })
      try {
        const query = createSearchTransactionExportQuery({
          fromDate: this.state.fromDate,
          toDate: this.state.toDate
        })
        const result = await this.props.exportTransaction(query)
        if (result.data) {
          this.setState({
            submitStatus: CONSTANT.LOADING_STATUS.SUCCESS
          })
          fetch()
        } else {
          this.setState({
            submitStatus: CONSTANT.LOADING_STATUS.FAILED
          })
        }
      } catch (error) {
        this.setState({ submitStatus: CONSTANT.LOADING_STATUS.FAILED })
      }
    }
  }
  closeConfirmationModal = e => {
    this.setState({ confirmationModalOpen: false, fromDate: '', toDate: '' })
  }
  onClickGenerate = e => {
    this.setState({ generateExportOpen: true })
  }
  onClickDownload = id => async e => {
    this.props.downloadExportFileById(id)
  }
  rowRenderer = (key, data, row) => {
    switch (key) {
      case 'created_at':
        return (
          <TimestampContainer>
            <span>{moment(row.created_at).format()}</span>
            {row.status === 'completed' && (
              <Icon name='Download' onClick={this.onClickDownload(row)} />
            )}
          </TimestampContainer>
        )
      case 'filename':
        if (row.status === 'completed') {
          return <a onClick={this.onClickDownload(row)}>{row.filename}</a>
        } else if (row.status === 'processing' || row.status === 'new') {
          return (
            <div style={{ maxWidth: '450px' }}>
              <ProgressTextContainer>
                <span>Exporting...</span>
                <span>{row.completion.toFixed(2)}%</span>
              </ProgressTextContainer>
              <ProgressBar percentage={row.completion.toFixed(2)} />
            </div>
          )
        } else if (row.status === 'failed') {
          return (
            <div>
              <div>{row.filename}</div>
              <div style={{ color: 'red' }}>{row.failure_reason}</div>
            </div>
          )
        }
        return '-'
      case 'params_match_all':
        return row.params.match_all
          ? row.params.match_all.length
            ? row.params.match_all.map((query, i) => (
              <div style={{ whiteSpace: 'nowrap' }} key={i}>
                  [ {query.field} ] [ {query.comparator} :{' '}
                {moment(query.value).isValid()
                  ? moment(query.value).format()
                  : query.value}{' '}
                  ]
              </div>
            ))
            : '-'
          : '-'

      case 'params_match_any':
        return row.params.match_any
          ? row.params.match_any.length
            ? row.params.match_any.map((query, i) => (
              <div style={{ whiteSpace: 'nowrap' }} key={i}>
                  [ {query.field} ] [ {query.comparator} :{' '}
                {moment(query.value).isValid()
                  ? moment(query.value).format()
                  : query.value}{' '}
                  ]
              </div>
            ))
            : '-'
          : '-'
      case 'status':
        return (
          <StatusContainer>
            {data === 'failed' && (
              <MarkContainer status='failed'>
                <Icon name='Close' />
              </MarkContainer>
            )}
            {data === 'completed' && (
              <MarkContainer status='success'>
                <Icon name='Checked' />
              </MarkContainer>
            )}
            {data === 'processing' && (
              <img
                src={require('../../statics/images/loading.gif')}
                width={20}
                style={{ verticalAlign: 'middle' }}
              />
            )}{' '}
            <span>{_.capitalize(data)}</span>
          </StatusContainer>
        )
      default:
        return data
    }
  }
  onClickClose = e => {
    this.setState({ generateExportOpen: false })
  }
  render () {
    return (
      <Container>
        <ExportFetcher
          query={{
            page: queryString.parse(this.props.location.search)['page'],
            perPage: 10
          }}
          render={({ data, individualLoadingStatus, pagination, fetch }) => {
            return (
              <>
                <TopNavigation
                  divider={this.props.divider}
                  title={
                    <TitleContainer>
                      <Icon name='Arrow-Left' onClick={this.props.history.goBack} />
                      <span>Export Transactions</span>
                    </TitleContainer>
                  }
                  secondaryAction={false}
                />

                <ContentContainer>
                  <ActionContainer>
                    <div className='title'>
                      <div>Select the range you want to export.</div>
                      <div>The export format will be CSV.</div>
                    </div>

                    <FormDetailContainer onSubmit={this.onClickExport(fetch)}>
                      <div>
                        <Tag title='Start' small />
                        <div className='row'>
                          <DatePicker
                            onChange={this.onDateFromChange}
                            onFocus={this.onDateFromFocus}
                            value={this.state.fromDate}
                          />
                          <TimePicker
                            onChange={this.onTimeFromChange}
                            onFocus={this.onTimeFromFocus}
                            value={this.state.fromTime}
                          />
                        </div>
                      </div>

                      <div>
                        <Tag title='End' small />
                        <div className='row'>
                          <DatePicker
                            onChange={this.onDateToChange}
                            onFocus={this.onDateToFocus}
                            value={this.state.toDate}
                          />
                          <TimePicker
                            onChange={this.onTimeToChange}
                            onFocus={this.onTimeToFocus}
                            value={this.state.toTime}
                          />
                        </div>
                      </div>
                    </FormDetailContainer>

                    <Button
                      onClick={this.onClickExport(fetch)}
                      loading={this.state.submitStatus === CONSTANT.LOADING_STATUS.PENDING}
                    >
                      <span>Export</span>
                    </Button>
                  </ActionContainer>

                  <TableContainer>
                    <SortableTable
                      rows={data}
                      columns={columns}
                      loadingStatus={individualLoadingStatus}
                      isFirstPage={pagination.is_first_page}
                      isLastPage={pagination.is_last_page}
                      navigation
                      rowRenderer={this.rowRenderer}
                      loadingEffect={false}
                    />
                  </TableContainer>
                </ContentContainer>

                <ConfirmationModal
                  open={this.state.confirmationModalOpen}
                  onRequestClose={this.closeConfirmationModal}
                  onOk={this.onClickExport(fetch, true)}
                >
                  <AlertEmptyTextContainer>
                    <div>
                      Leaving the date fields empty will generate an export for{' '}
                      <span>all the transactions</span> since the beginning of time.
                    </div>
                    <div>Do you want to proceed?</div>
                  </AlertEmptyTextContainer>
                </ConfirmationModal>
              </>
            )
          }}
        />
      </Container>
    )
  }
}

class TimePicker extends PureComponent {
  static propTypes = {
    onChange: PropTypes.func,
    value: PropTypes.oneOfType([PropTypes.object, PropTypes.string]),
    onFocus: PropTypes.func
  }
  render () {
    return (
      <DateTime
        className='date-time'
        closeOnSelect
        onChange={this.props.onChange}
        dateFormat={false}
        renderInput={(props) => {
          return (
            <Input
              {...props}
              value={this.props.value && this.props.value.format('hh:mm a')}
              onFocus={this.props.onFocus}
              placeholder='Time'
              normalPlaceholder='00 : 00'
              icon='Time'
              inputActive
            />
          )
        }}
      />
    )
  }
}

class DatePicker extends PureComponent {
  static propTypes = {
    onChange: PropTypes.func,
    value: PropTypes.oneOfType([PropTypes.object, PropTypes.string]),
    onFocus: PropTypes.func
  }
  render () {
    return (
      <DateTime
        className='date-time'
        closeOnSelect
        onChange={this.props.onChange}
        timeFormat={false}
        renderInput={(props) => {
          return (
            <Input
              {...props}
              value={this.props.value && this.props.value.format('DD/MM/YY')}
              onFocus={this.props.onFocus}
              placeholder='Date'
              normalPlaceholder='00/00/00'
              icon='Calendar'
              inputActive
            />
          )
        }}
      />
    )
  }
}

export default enhance(TransactionExportPage)

// value={this.props.value && this.props.value.format('DD/MM/YYYY hh:mm:ss a')}
