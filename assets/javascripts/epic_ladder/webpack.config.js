const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const { WebpackManifestPlugin } = require('webpack-manifest-plugin');
const webpack = require('webpack');

const isProduction = process.env.NODE_ENV === 'production';

module.exports = {
  mode: isProduction ? 'production' : 'development',
  devtool: isProduction ? 'source-map' : 'eval-source-map',
  entry: isProduction ? './src/index.production.tsx' : './src/index.tsx',
  output: {
    path: path.resolve(__dirname, '../../build'),
    filename: isProduction
      ? 'kanban_bundle.[contenthash:8].js'
      : 'kanban_bundle.js',
    clean: true,
  },
  optimization: {
    splitChunks: false, // コード分割を無効化（Redmineアセットパイプライン対応）
  },
  devServer: {
    static: [
      {
        directory: path.resolve(__dirname, '../../build'),
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
        test: /\.(js|mjs)$/,
        enforce: 'pre',
        use: ['source-map-loader'],
        exclude: /node_modules/,
      },
      {
        test: /\.(ts|tsx)$/,
        exclude: [
          /node_modules/,
          /\.test\.(ts|tsx)$/,
          /\.spec\.(ts|tsx)$/,
          /mockData\.ts$/,
          /setupTests\.ts$/,
          /mocks/,
        ],
        use: {
          loader: 'ts-loader',
          options: {
            // 本番環境では型チェックを完全にスキップ
            transpileOnly: true,
            compilerOptions: {
              sourceMap: !isProduction,
            },
          },
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
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(isProduction ? 'production' : 'development'),
    }),
    new HtmlWebpackPlugin({
      template: './nested_grid_test_template.html',
      filename: 'index.html',
    }),
    new CopyWebpackPlugin({
      patterns: [
        { from: 'public', to: '.' }
      ]
    }),
    new WebpackManifestPlugin({
      fileName: 'asset-manifest.json',
      publicPath: '/plugin_assets/redmine_epic_ladder/',
    }),
    // mocksをno-op実装に置き換え（開発・本番共通）
    new webpack.NormalModuleReplacementPlugin(
      /\/mocks\/browser$/,
      './mocks/browser.noop.ts'
    ),
  ],
  resolve: {
    extensions: ['.ts', '.tsx', '.js', '.jsx'],
    alias: {
      react: path.resolve(__dirname, 'node_modules/react'),
      'react-dom': path.resolve(__dirname, 'node_modules/react-dom'),
    },
  },
};
