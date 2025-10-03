// plugins/redmine_release_kanban/webpack.config.js
const path = require("path");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
  mode: "development",
  entry: "./assets/javascripts/kanban/src/index.tsx",
  output: {
    filename: "kanban_bundle.js",
    path: path.resolve(__dirname, "assets/javascripts/kanban/dist"),
    clean: true,
  },
  optimization: {
    splitChunks: false, // コード分割を無効化（Redmineアセットパイプライン対応）
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
          loader: "ts-loader",
          options: {
            configFile: path.resolve(__dirname, "assets/javascripts/kanban/tsconfig.json"),
          },
        },
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"],
      },
      {
        test: /\.scss$/,
        use: [
          "style-loader",
          "css-loader",
          {
            loader: "sass-loader",
            options: {
              implementation: require("sass-embedded"),
            },
          },
        ],
      },
    ],
  },
  ignoreWarnings: [/Failed to parse source map/],
  resolve: {
    extensions: [".js", ".jsx", ".ts", ".tsx"],
    alias: {
      'tailwindcss/version.js': false,
    },
  },
  devServer: {
    static: [
      {
        directory: path.resolve(__dirname, "assets/javascripts/kanban/dist"),
        publicPath: "/",
      },
      {
        directory: path.resolve(__dirname, "assets/javascripts/kanban/public"),
        publicPath: "/",
      }
    ],
    devMiddleware: {
      writeToDisk: true, // 物理ファイルに書き出し（Redmineから参照するため）
    },
    hot: true,
    liveReload: true,
    port: 8080,
    compress: true,
    allowedHosts: 'all',
    headers: {
      "Access-Control-Allow-Origin": "*"
    },
    client: {
      overlay: {
        warnings: false,
        errors: true,
      },
    },
  },
  plugins: [
    // 開発用HTMLファイル生成
    new HtmlWebpackPlugin({
      template: path.resolve(__dirname, "assets/javascripts/kanban/nested_grid_test_template.html"),
      filename: "index.html",
    }),
    // Webpack出力完了後にコピーを実行
    new CopyWebpackPlugin({
      patterns: [
        // CSSファイルのコピー（ビルド処理と関係ない）
        {
          from: path.resolve(__dirname, "assets/stylesheets/kanban/kanban.css"),
          to: "/usr/src/redmine/public/plugin_assets/redmine_release_kanban/kanban.css",
          noErrorOnMissing: false,
          force: true
        },
        // grid_v2.css のコピー (GridStatistics.css統合済み)
        {
          from: path.resolve(__dirname, "assets/stylesheets/kanban/grid_v2.css"),
          to: "/usr/src/redmine/public/plugin_assets/redmine_release_kanban/grid_v2.css",
          noErrorOnMissing: false,
          force: true
        },
        // MSW用ファイル
        {
          from: path.resolve(__dirname, "assets/javascripts/kanban/public"),
          to: path.resolve(__dirname, "assets/javascripts/kanban/dist"),
          noErrorOnMissing: true,
        }
      ],
    }),
    // カスタムプラグイン: ビルド完了後にJSファイルをコピー
    {
      apply: (compiler) => {
        compiler.hooks.afterEmit.tap('CopyJSAfterEmit', () => {
          const fs = require('fs');
          const srcPath = path.resolve(__dirname, "assets/javascripts/kanban/dist/kanban_bundle.js");
          const destPath = "/usr/src/redmine/public/plugin_assets/redmine_release_kanban/kanban_bundle.js";

          // ディレクトリが存在しない場合は作成
          const destDir = path.dirname(destPath);
          if (!fs.existsSync(destDir)) {
            fs.mkdirSync(destDir, { recursive: true });
          }

          // ファイルをコピー
          if (fs.existsSync(srcPath)) {
            fs.copyFileSync(srcPath, destPath);
            console.log(`✓ Copied ${srcPath} to ${destPath}`);
          }
        });
      }
    }
  ],
};
