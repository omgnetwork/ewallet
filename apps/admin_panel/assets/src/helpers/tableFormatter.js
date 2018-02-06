import numberWithCommas from './numberFormatter';
import tableConstants from '../constants/table.constants';

export function formatHeader(row, key) {
  const obj = row[key];
  if (obj.type === tableConstants.PROPERTY) {
    switch (typeof obj.value) {
      case 'object':
        return {
          key,
          className: 'omg-table-content-row__center',
        };
      case 'number':
        return {
          key,
          className: 'omg-table-content-row__right',
        };
      default:
        return {
          key,
          className: 'omg-table-content-row__left',
        };
    }
  } else {
    return {
      key,
      className: 'omg-table-content-row__left',
    };
  }
}

export function formatContent(value) {
  switch (typeof value) {
    case 'object':
      return { content: value, className: 'omg-table-content-row__center' };
    case 'number':
      return { content: numberWithCommas(value), className: 'omg-table-content-row__right' };
    default:
      return { content: `${value}`, className: 'omg-table-content-row__left' };
  }
}

export const defaultHeaderAlignment = () => ({
  className: 'omg-table-content-row__left', key: '',
});
