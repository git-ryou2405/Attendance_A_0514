source 'https://rubygems.org'

gem 'rails',        '~> 5.1.6'
gem 'rails-i18n'                # 日本語化
gem 'bcrypt'                    # 暗号化 "Use ActiveModel has_secure_password"
gem 'faker'                     # ダミーデータ自動生成用
gem 'roo'                       # csvファイル読込用（Excel, CSV, OpenOffice, GoogleSpreadSheetを開くことが可能）
gem 'tod'                       # 時刻のパース

gem 'will_paginate'             # ページネション
gem 'bootstrap-will_paginate'   # ページネション

gem 'sass-rails',   '~> 5.0'    # SCSS(Syntactically Awesome StyleSheet：効率的にCSSが書ける言語) 
gem 'bootstrap-sass'

gem 'rounding'                  # 時間だけでなく、数値全般を扱える

gem 'puma',         '~> 3.12'
gem 'sass-rails',   '~> 5.0'
gem 'uglifier',     '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks',   '~> 5'
gem 'jbuilder',     '~> 2.5'

group :development, :test do
  gem 'sqlite3', '1.3.13'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  gem "pry-rails"
  gem "pry-byebug"

  gem 'hirb'                      # モデルの出力結果を表形式で表示するGem
  gem 'hirb-unicode'              # 日本語などマルチバイト文字の出力時の出力結果のずれに対応
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :production do
  gem 'pg', '0.20.0'
end

# Windows環境ではtzinfo-dataというgemを含める必要があります
# Mac環境でもこのままでOKです
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]