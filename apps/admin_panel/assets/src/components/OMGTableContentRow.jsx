import React from 'react';
import PropTypes from 'prop-types';
import numberWithCommas from '../helpers/numberFormatter';
import OMGTruncatedCell from './OMGTruncatedCell';

const OMGTableContentRow = ({ data, shortenedColumnIds }) => {
  const tds = Object.keys(data).map((key) => {
    const value = data[key];
    let obj;
    switch (typeof value) {
      case 'object':
        obj = { content: value, className: 'omg-table-content-row__center' };
        break;
      case 'number':
        obj = { content: numberWithCommas(value), className: 'omg-table-content-row__right' };
        break;
      default:
        obj = { content: `${value}`, className: 'omg-table-content-row__left' };
        break;
    }
    return (
      <td key={key} className={obj.className}>
        {shortenedColumnIds.includes(key) ?
          <OMGTruncatedCell content={obj.content} /> : obj.content
        }
      </td>
    );
  });
  return (
    <tr>
      {tds}
    </tr>
  );
};

OMGTableContentRow.propTypes = {
  data: PropTypes.object.isRequired,
  shortenedColumnIds: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default OMGTableContentRow;
