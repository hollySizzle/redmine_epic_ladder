const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
  mode: process.env.NODE_ENV === 'production' ? 'production' : 'development',
  entry: './src/index.tsx',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'kanban_bundle.js',
    clean: true,
  },
  optimization: {
    splitChunks: false, // コード分割を無効化（Redmineアセットパイプライン対応）
  },
  devServer: {
    static: [
      {
        directory: path.join(__dirname, 'dist'),
      },
      {
        directory: path.join(__dirname, 'public'),
        publicPath: '/',
      }
    ],
    compress: true,
    port: 9000,
    open: true,
    hot: true,
    client: {
      overlay: {
        warnings: false,
        errors: true,
      },
    },
  },
  module: {
    rules: [
      {
        test: /\.(ts|tsx)$/,
        exclude: [
          /node_modules/,
          /\.test\.(ts|tsx)$/,
          /\.spec\.(ts|tsx)$/,
          /mockData\.ts$/,
          /setupTests\.ts$/,
          /mocks\/server\.ts$/,
        ],
        use: {
          loader: 'ts-loader',
        },
      },
      {
        test: /\.scss$/,
        use: [
          'style-loader',
          'css-loader',
          {
            loader: 'sass-loader',
            options: {
              implementation: require('sass-embedded'),
            },
          },
        ],
      },
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: './nested_grid_test_template.html',
      filename: 'index.html',
    }),
    new CopyWebpackPlugin({
      patterns: [
        { from: 'public', to: '.' }
      ]
    }),
  ],
  resolve: {
    extensions: ['.ts', '.tsx', '.js', '.jsx'],
  },
};
