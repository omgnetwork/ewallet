export class LoginParams {
  constructor(attrs) {
    this.email = attrs.email;
    this.password = attrs.password;
  }

  params() {
    return JSON.stringify(this);
  }
}
