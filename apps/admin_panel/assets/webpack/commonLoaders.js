
module.exports = [
  {
    test: /\.jsx?$/,
    use: [
      {
        loader: 'babel-loader',
        options: {
          presets: [['@babel/preset-env', {
            'targets': {
              'node': 'current'
            }
          }], '@babel/preset-react'],
          plugins: [
            require('@babel/plugin-proposal-class-properties'),
            require('@babel/plugin-proposal-object-rest-spread'),
            'react-hot-loader/babel']
        }
      }
    ],
    exclude: /node_modules/
  },
  {
    test: /\.placeholder\.(jpg|png)$/,
    loader: 'url-loader?name=assets/images/[hash].[ext]&limit=4096'
  },
  {
    test: /\.(svg|png)(\?.*)?$/,
    exclude: /\.placeholder\.(jpg|png)$/,
    loader: 'url-loader?name=assets/images/[hash].[ext]&limit=4096'
  },

  {
    test: /\.jpg$/,
    exclude: /\.placeholder\.(jpg|png)$/,
    loader: 'file-loader?name=assets/images/[hash].[ext]'
  },
  {
    test: /\.gif$/,
    exclude: /\.placeholder\.(gif)$/,
    loader: 'file-loader?name=assets/images/[hash].[ext]'
  },
  {
    test: /\.(eot|woff2|woff|ttf|otf|)(\?.*)?$/,
    loader: 'file-loader?name=assets/fonts/[hash].[ext]'
  },
  {
    test: /\.css$/,
    use: [ 'style-loader', 'css-loader' ]
  }

]
