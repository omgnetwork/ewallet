const HtmlWebpackPlugin = require('html-webpack-plugin')
const commonLoaders = require('./commonLoaders')
const { DefinePlugin, ProvidePlugin } = require('webpack')
const path = require('path')
module.exports = {
  entry: [path.resolve(__dirname, '../src/index.js')],
  output: {
    path: path.resolve(__dirname, '../../priv/static'),
    publicPath: '/admin/',
    filename: 'bundle.js'
  },
  module: {
    rules: [
      ...commonLoaders
    ]
  },
  mode: 'production',
  stats: { colors: true },

  plugins: [
    new HtmlWebpackPlugin({ template: path.resolve(__dirname, './index.html') }),
    new ProvidePlugin({
      _: 'lodash'
    }),
    new DefinePlugin({
      CONFIG: {
        BACKEND_API_URL: JSON.stringify(process.env.BACKEND_API_URL),
        BACKEND_WEBSOCKET_URL: JSON.stringify(process.env.BACKEND_WEBSOCKET_URL)
      }
    })
  ]
}
