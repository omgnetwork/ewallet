import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import queryString from 'query-string'
import moment from 'moment'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
import { connect } from 'react-redux'

import { Button, Icon, Tag, Tooltip, DatePicker, TimePicker } from '../omg-uikit'
import SortableTable from '../omg-table'
import ExportFetcher from '../omg-export/exportFetcher'
import { downloadExportFileById, getExports } from '../omg-export/action'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { exportTransaction } from '../omg-transaction/action'
import { createSearchTransactionExportQuery } from './searchField'
import CONSTANT from '../constants'
import ConfirmationModal from '../omg-confirmation-modal'

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

    > div {
      &:first-child {
        margin-right: 20px;
      }
    }
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
      cursor: pointer;
      background-color: ${props => props.theme.colors.BL400};
      color: white;
    }
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
  width: 50%;
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
const RangeContainer = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;

  i {
    margin-right: 20px;
  }

  .range-group {
    display: flex;
    flex-direction: column;

    .range-item {
      display: flex;
      span:first-child {
        padding-right: 5px;
        font-weight: bold;
      }
    }
  }
`
const columns = [
  { key: 'range', title: 'EXPORTED RANGE' },
  { key: 'timestamp', title: 'TIMESTAMP' }
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
    let _fromDate = this.state.fromDate
    let _toDate = this.state.toDate

    if (this.state.fromTime) {
      _fromDate = this.state.fromDate.set({
        hour: this.state.fromTime.get('hour'),
        minute: this.state.fromTime.get('minute')
      })
    }

    if (this.state.toTime) {
      _toDate = this.state.toDate.set({
        hour: this.state.toTime.get('hour'),
        minute: this.state.toTime.get('minute')
      })
    }

    e.preventDefault()
    if (!this.state.fromDate && !this.state.toDate && !confirm) {
      this.setState({ confirmationModalOpen: true })
    } else {
      this.setState({ submitStatus: CONSTANT.LOADING_STATUS.PENDING, confirmationModalOpen: false })
      try {
        const query = createSearchTransactionExportQuery({
          fromDate: _fromDate,
          toDate: _toDate
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
      case 'range':
        if (row.status === 'completed') {
          const ranges = row.params.match_all
          const start = _.first(ranges.filter(i => i.comparator === 'gte'))
          const end = _.first(ranges.filter(i => i.comparator === 'lte'))

          return (
            <RangeContainer>
              <Icon name='Export' />
              <div className='range-group'>
                <div className='range-item'>
                  <span>Start</span>
                  <span>{moment(start.value).format('MM/DD/YYYY H:mm')}</span>
                </div>
                {end && (
                  <div className='range-item'>
                    <span>End</span>
                    <span>{moment(end.value).format('MM/DD/YYYY H:mm')}</span>
                  </div>
                )}
                {!end && (
                  <div className='range-item'>
                    <span>End</span>
                    <span>{moment(row.created_at).format('MM/DD/YYYY H:mm')}</span>
                  </div>
                )}
              </div>
            </RangeContainer>
          )
        }
        return null
      case 'timestamp':
        return (
          <TimestampContainer>
            <span>{moment(row.created_at).format('MM/DD/YYYY H:mm')}</span>
            {row.status === 'completed' && (
              <Tooltip text='Download'>
                <Icon name='Download' onClick={this.onClickDownload(row)} />
              </Tooltip>
            )}
          </TimestampContainer>
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
                  searchBar={false}
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
                      hoverEffect={false}
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

export default enhance(TransactionExportPage)
