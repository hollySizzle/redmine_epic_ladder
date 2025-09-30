// plugins/redmine_release_kanban/webpack.config.js
const path = require("path");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
  mode: "development", // or 'production'
  entry: "./assets/javascripts/kanban/index.jsx",
  output: {
    filename: "kanban_bundle.js",
    path: path.resolve(__dirname, "assets/javascripts/kanban/dist"),
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            presets: ["@babel/preset-env", "@babel/preset-react"],
          },
        },
      },
      {
        test: /\.css$/,
        use: [
          "style-loader",
          "css-loader",
          {
            loader: "postcss-loader",
            options: {
              postcssOptions: {
                plugins: [require("tailwindcss"), require("autoprefixer")],
              },
            },
          },
        ],
      },
      {
        test: /\.scss$/,
        use: [
          "style-loader",
          "css-loader",
          {
            loader: "postcss-loader",
            options: {
              postcssOptions: {
                plugins: [require("tailwindcss"), require("autoprefixer")],
              },
            },
          },
          "sass-loader",
        ],
      },
    ],
  },
  ignoreWarnings: [/Failed to parse source map/],
  resolve: {
    extensions: [".js", ".jsx"],
    alias: {
      'tailwindcss/version.js': false,
    },
  },
  plugins: [
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
      ],
    }),
    // カスタムプラグイン: ビルド完了後にJSファイルをコピー
    {
      apply: (compiler) => {
        compiler.hooks.afterEmit.tap('CopyJSAfterEmit', (compilation) => {
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
