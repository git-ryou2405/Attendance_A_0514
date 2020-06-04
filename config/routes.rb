Rails.application.routes.draw do
  get 'bases/new'

  get 'sessions/new'

  root 'static_pages#top'
  get '/signup', to: 'users#new'
  
  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
    resources :users do
      member do
        get 'edit_basic_info'
        get 'edit_basic_info_admin'
        get 'working_list'
        patch 'update_basic_info'
        get 'attendances/edit_one_month'
        patch 'attendances/update_one_month'
        
        get 'attendances/req_overtime'
        patch 'attendances/update_overtime'
        get 'attendances/notice_overtime'
        patch 'attendances/update_notice_overtime'
        get 'attendances/notice_change_at'
        patch 'attendances/update_notice_change_at'
        get 'reports/notice_report'
        patch 'reports/update_report'
        
      end
      collection {post :import}
      resources :attendances, only: :update
      resources :reports, only: :create
    end
    resources :bases do
    end
  end