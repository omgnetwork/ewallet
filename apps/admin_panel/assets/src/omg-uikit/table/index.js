import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { LoadingSkeleton } from '../../omg-uikit'
import Pagination from './Pagination'
import Fade from '../../omg-transition/Fade'
const StyledPagination = styled(Pagination)`
  margin: 20px auto;
`
const TableContainer = styled.div`
  position: relative;
  min-height: ${props => (props.loading ? `${props.height}px` : 'auto')};
  overflow-x: auto;
  overflow-y: hidden;
`
const EmptyStageContainer = styled.div`
  text-align: center;
  width: 100%;
  color: ${props => props.theme.colors.S500};
  > img {
    width: 150px;
    margin: 0 auto;
    display: inline-block;
    margin-top: 50px;
    margin-bottom: 20px;
  }
`
const Tr = styled.tr`
  background-color: ${props => (props.active ? props.theme.colors.S200 : 'transparent')};
`
class Table extends Component {
  static propTypes = {
    columns: PropTypes.array,
    columnRenderer: PropTypes.func,
    rows: PropTypes.array,
    rowRenderer: PropTypes.func,
    onClickRow: PropTypes.func,
    onClickPagination: PropTypes.func,
    loadingRowNumber: PropTypes.number,
    loadingColNumber: PropTypes.number,
    loading: PropTypes.bool,
    page: PropTypes.number,
    pagination: PropTypes.bool,
    perPage: PropTypes.number,
    activeIndexKey: PropTypes.string
  }
  static defaultProps = {
    columns: [],
    rows: [],
    loadingRowNumber: Math.round(window.innerHeight / 60),
    loadingColNumber: 5,
    page: 1,
    perPage: 1000,
    pagination: false,
    onClickRow: () => {}
  }
  constructor (props) {
    super(props)
    this.loadingWidthBars = new Array(this.props.loadingRowNumber).fill().map((x, i) => {
      return `${30 + Math.random() * 40}%`
    })
  }
  onClickPagination = page => e => {
    if (this.props.onClickPagination) {
      this.props.onClickPagination(page)
    }
  }
  renderLoadingColumns = () => {
    return (
      <tr>
        <th style={{ height: '20px' }} />
      </tr>
    )
  }
  renderColumns = () => {
    return (
      <tr>
        {this.props.columnRenderer
          ? this.props.columns.map(x => this.props.columnRenderer(x))
          : this.props.columns.map(x => <th key={x.key}>{x.title}</th>)}
      </tr>
    )
  }
  renderLoadingRows = () => {
    return this.loadingWidthBars.map((x, i) => {
      return (
        <tr key={`row-${i}`} ref={row => (this.row = row)}>
          <td key={`col-rest-${i}`}>
            <LoadingSkeleton height={'12px'} width={x} style={{ margin: '5px 0' }} />
          </td>
        </tr>
      )
    })
  }
  renderDataRows = () => {
    const start = (this.props.page - 1) * this.props.perPage
    const end = start + this.props.perPage
    const source =
      this.props.perPage && this.props.pagination
        ? this.props.rows.slice(start, end)
        : this.props.rows
    return source.map((d, i) => {
      return (
        <Tr
          key={d.id}
          ref={row => (this.row = row)}
          onClick={this.props.onClickRow(d, i)}
          active={this.props.activeIndexKey === d.id}
        >
          {this.props.columns
            .filter(c => !c.hide)
            .map((c, j) => (
              <td key={`col-rest-${j}`}>
                {this.props.rowRenderer ? this.props.rowRenderer(c.key, d[c.key], d) : d[c.key]}
              </td>
            ))}
        </Tr>
      )
    })
  }
  render () {
    const dataRows = this.renderDataRows()
    return (
      <TableContainer
        innerRef={table => (this.table = table)}
        height={this.props.loadingRowNumber * 40}
        loading={this.props.loading}
      >
        <Fade in={this.props.loading} timeout={300} key={'loading'} unmountOnExit>
          <table style={{ position: 'absolute', background: 'white' }}>
            <thead>{this.renderLoadingColumns()}</thead>
            <tbody>{this.renderLoadingRows()}</tbody>
          </table>
        </Fade>
        <Fade in={!this.props.loading} timeout={300} key={'data'} unmountOnExit appear>
          <table>
            <thead>{this.renderColumns()}</thead>
            {!!dataRows.length && <tbody>{this.renderDataRows()}</tbody>}
          </table>
        </Fade>
        {!dataRows.length && (
          <EmptyStageContainer>
            <img src={require('../../../statics/images/Empty state_1.0_Empty-state_1.0.png')} />
            <div>Sorry, no data yet.</div>
          </EmptyStageContainer>
        )}
        {!this.props.loading && this.props.pagination && (
          <StyledPagination
            itemCounts={this.props.rows.length}
            perPage={this.props.perPage}
            activeKey={this.props.page}
            onClickPagination={this.onClickPagination}
          />
        )}
      </TableContainer>
    )
  }
}

export default Table
