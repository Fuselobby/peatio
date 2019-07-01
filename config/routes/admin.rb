# encoding: UTF-8
# frozen_string_literal: true

namespace :admin do
  get '/', to: 'dashboard#index', as: :dashboard

  resources :campaign_posts, except: %i[new destroy]
  resources :incentive_histories, only: :index
  resources :wallets_summary, only: :index
  resources :campaign_logs, only: %i[index show]
  resources :campaign_options, except: :destroy
  resources :campaigns, except: :destroy do
    get :add_post, on: :member
    post :add_post_action, on: :member
  end
  resources :analysts, except: %i[edit destroy]
  resources :markets, except: %i[edit destroy]
  resources :currencies, except: %i[edit destroy]
  resources :blockchains, except: %i[edit destroy]
  resources :wallets, except: %i[edit destroy] do
    post :show_client_info, on: :collection
  end

  resources :members, only: %i[index show]

  resources 'deposits/:currency',  to: AdminDepositsRouter.new,  as: 'deposit'
  resources 'withdraws/:currency', to: AdminWithdrawsRouter.new, as: 'withdraw'

  %i[liability asset revenue expense].each do |type|
    get "operations/#{type.to_s.pluralize}/(:currency)",
      to: AdminOperationsRouter.new(type),
      as: "#{type}_operations"
  end

  get :balance_sheet,  controller: 'accountings'
  get :income_statement, controller: 'accountings'
  get :analysts_sheet, controller: 'analysts'
  get :hot_trade, controller: 'analysts'
  get :top_spender, controller: 'analysts'
  get :top_trader, controller: 'analysts'
end
