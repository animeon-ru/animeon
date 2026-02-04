# frozen_string_literal: true
require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  apipie
  namespace :api, defaults: { format: 'json' } do
    scope module: :v1 do
      resources :user_rates, only: [:update]
      resources :animes, only: [:index] do
        collection do
          get :search
        end
      end
      resources :videos, only: %i[index create update show] do
        member do
          patch :update_status
          put :update_status
          get :increase_views
          post :presign
        end
      end
      resources :db_modifications, only: %i[destroy] do
        post :approve
        post :rollback
      end
    end
  end
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  ani_manga_format = <<-FORMAT.gsub(/[\n ]/, '')
    (/kind/:kind)
    (/status/:status)
    (/franchise/:franchise)
    (/genres/:genres)
    (/studio/:studio)
    (/with/:model)
  FORMAT

  get "animes#{ani_manga_format}" => 'animes#index',
      as: 'animes',
      constraints: {
        page: /\d+/
      }

  root 'dashboard#index'
  resources :user, only: %i[show], controller: 'users/users' do
    resource :list, only: %i[index] do
      get :anime
    end
  end

  resources :news, only: %i[show new create index]

  resources :admin, only: %i[index] do
    collection do
      get :blank_params
      get :need_to_fill
    end
  end

  resources :animes, only: %i[show new create edit update] do
    collection do
      get :new_from_shikimori
      post :create_from_shikimori
    end
    resources :episodes, only: %i[show new create edit update] do
      resources :videos, only: %i[new edit update]
    end
    post :decrement_episode
    post :increment_episode
    post :user_status
    get :information
  end
end
