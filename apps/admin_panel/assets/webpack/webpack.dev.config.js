const HtmlWebpackPlugin = require('html-webpack-plugin')
const commonLoaders = require('./commonLoaders')
const { DefinePlugin, ProvidePlugin } = require('webpack')
const path = require('path')
require('dotenv').config()
module.exports = {
  entry: [path.resolve(__dirname, '../src/index.js')],
  mode: 'development',
  output: {
    path: path.resolve(__dirname, '../build/'),
    publicPath: '/',
    filename: 'bundle.js'
  },
  devtool: 'eval-source-map',

  devServer: {
    historyApiFallback: true,
    hot: true,
    inline: true,
    port: 9000
  },

  module: {
    rules: [...commonLoaders]
  },

  plugins: [
    new HtmlWebpackPlugin({ template: path.resolve(__dirname, './index.html') }),
    new ProvidePlugin({
      _: 'lodash'
    }),
    new DefinePlugin({
      BACKEND_URL: JSON.stringify(process.env.BACKEND_URL)
    })
  ]
}
