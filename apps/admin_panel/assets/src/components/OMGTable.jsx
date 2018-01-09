import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { Table } from 'react-bootstrap';
import OMGTableHeader from './OMGTableHeader';
import OMGTableContentRow from './OMGTableContentRow';

class OMGTable extends Component {
  constructor() {
    super();
    this.state = {
      sortedColumnIndex: 0,
      sortedColumnMode: 'asc',
    };
    this.sort = this.sort.bind(this);
  }

  sort(sortedColumnIndex, sortedColumnMode) {
    this.setState(
      {
        sortedColumnIndex,
        sortedColumnMode,
      },
      () => {
        const { updateSorting, headerTitles } = this.props;
        updateSorting(headerTitles[sortedColumnIndex], sortedColumnMode);
      },
    );
  }

  render() {
    const { sortedColumnIndex, sortedColumnMode } = this.state;
    const { headerTitles } = this.props;
    const headers = headerTitles.map((title, index) => (
      <OMGTableHeader
        key={index} // eslint-disable-line react/no-array-index-key
        handleClick={this.sort}
        position={index}
        sortBy={index === sortedColumnIndex ? sortedColumnMode : 'default'}
        title={title}
      />
    ));

    const { contents } = this.props;

    const datas = contents.map(data => <OMGTableContentRow key={data.id} data={data} />);

    return (
      <Table responsive>
        <thead>
          <tr>
            {headers}
          </tr>
        </thead>
        <tbody>
          {datas}
        </tbody>
      </Table>
    );
  }
}

OMGTable.propTypes = {
  contents: PropTypes.array.isRequired,
  headerTitles: PropTypes.arrayOf(PropTypes.string).isRequired,
  updateSorting: PropTypes.func.isRequired,
};

export default OMGTable;
