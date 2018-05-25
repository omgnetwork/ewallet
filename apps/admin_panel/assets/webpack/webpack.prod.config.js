const HtmlWebpackPlugin = require("html-webpack-plugin")
const commonLoaders = require("./commonLoaders")
const webpack = require("webpack")
const path = require("path")
// const MiniCssExtractPlugin = require('mini-css-extract-plugin')
// const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
module.exports = {
  entry: [path.resolve(__dirname, "../src/index.js")],
  output: {
    path: path.resolve(__dirname, "../../priv/static"),
    publicPath: "/admin/",
    filename: "bundle.js"
  },
  module: {
    rules: [
      ...commonLoaders
      // {
      //   test: /\.css$/,
      //   use: [
      //     MiniCssExtractPlugin.loader,
      //     'css-loader'
      //   ]
      // }
    ]
  },
  mode: "production",
  stats: { colors: true },

  plugins: [
    new HtmlWebpackPlugin({ template: path.resolve(__dirname, "./index.html") }),
    new webpack.ProvidePlugin({
      _: "lodash"
    })
    // new MiniCssExtractPlugin({
    //   // Options similar to the same options in webpackOptions.output
    //   // both options are optional
    //   filename: '[name].css',
    //   chunkFilename: '[id].css'
    // })
    // new BundleAnalyzerPlugin()
  ]
}
