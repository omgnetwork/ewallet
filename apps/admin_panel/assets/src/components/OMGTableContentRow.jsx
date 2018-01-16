import React from 'react';
import PropTypes from 'prop-types';
import numberWithCommas from '../helpers/numberFormatter';
import OMGTruncatedCell from './OMGTruncatedCell';

const OMGTableContentRow = ({ data, shortenedColumnIndexes }) => {
  const tds = Object.values(data)
    .map((v) => {
      switch (typeof v) {
        case 'object':
          return { content: v, className: 'omg-table-content-row__center' };
        case 'number':
          return { content: numberWithCommas(v), className: 'omg-table-content-row__right' };
        default:
          return { content: `${v}`, className: 'omg-table-content-row__left' };
      }
    })
    .map((obj, index) => (
      <td key={index} className={obj.className}>
        {shortenedColumnIndexes.includes(index) ?
          <OMGTruncatedCell content={obj.content} /> : obj.content
        }
      </td>
    ));
  return (
    <tr>
      {tds}
    </tr>
  );
};

OMGTableContentRow.propTypes = {
  data: PropTypes.object.isRequired,
  shortenedColumnIndexes: PropTypes.arrayOf(PropTypes.number).isRequired,
};

export default OMGTableContentRow;
