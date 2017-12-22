export class NewAccountParams {
  constructor(attrs) {
    this.name = attrs.name;
    this.description = attrs.description;
  }

  params() {
    return JSON.stringify(this);
  }
}

export class GetAccountsParams {
  constructor(attrs) {
    this.current_page = attrs.page
    this.per = attrs.per
    this.query = attrs.query;
  }

  params() {
    return JSON.stringify(this);
  }
}
