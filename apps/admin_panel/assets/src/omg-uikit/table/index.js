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
    perPage: PropTypes.number
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

  onClickPagination = page => e => {
    if (this.props.onClickPagination) {
      this.props.onClickPagination(page)
    }
  }
  renderLoadingColumns = () => {
    return (
      <tr>
        {new Array(this.props.loadingColNumber).fill().map((x, i) => {
          return (
            <th key={`col-header-${i}`}>
              <LoadingSkeleton height={'25px'} />
            </th>
          )
        })}
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
  renderHeaderRows = () => {
    return <tr>{this.props.loading ? this.renderLoadingColumns() : this.renderColumns()}</tr>
  }
  renderLoadingRows = () => {
    return new Array(this.props.loadingRowNumber).fill().map((x, i) => {
      return (
        <tr key={`row-${i}`} ref={row => (this.row = row)}>
          {new Array(this.props.loadingColNumber).fill().map((c, j) => (
            <td key={`col-rest-${j}`}>
              <LoadingSkeleton />
            </td>
          ))}
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
        <tr key={d.id} ref={row => (this.row = row)} onClick={this.props.onClickRow(d, i)}>
          {this.props.columns
            .filter(c => !c.hide)
            .map((c, j) => (
              <td key={`col-rest-${j}`}>
                {this.props.rowRenderer ? this.props.rowRenderer(c.key, d[c.key], d) : d[c.key]}
              </td>
            ))}
        </tr>
      )
    })
  }
  render () {
    return (
      <TableContainer innerRef={table => (this.table = table)}>
        <Fade in={this.props.loading} timeout={300} key={'loadung'} unmountOnExit>
          {state => {
            return (
              <table style={{ position: 'absolute', background: 'white' }}>
                {/* <thead>{this.renderLoadingColumns()}</thead> */}
                <tbody>{this.renderLoadingRows()}</tbody>
              </table>
            )
          }}
        </Fade>
        <Fade in={!this.props.loading} timeout={300} key={'data'} unmountOnExit appear>
          {state => {
            return (
              <table>
                <thead>{this.renderColumns()}</thead>
                <tbody>{this.renderDataRows()}</tbody>
              </table>
            )
          }}
        </Fade>

        {!this.props.loading &&
          this.props.pagination && (
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
