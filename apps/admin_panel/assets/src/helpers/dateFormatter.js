class DateFormatter {
  constructor() {
    this.options = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    };
    this.format = this.format.bind(this);
  }

  format(date) {
    return new Date(date).toLocaleTimeString('en-us', this.options);
  }
}

export default new DateFormatter();
