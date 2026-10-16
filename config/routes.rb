Rails.application.routes.draw do
  root "tickets#new"

  resources :tickets, only: [ :new, :create ]
  get "t/:access_token", to: "tickets#show", as: :customer_ticket
  post "t/:access_token/comments", to: "comments#create", as: :customer_ticket_comments

  resource :session

  namespace :agent do
    resources :tickets, only: [ :index, :show ] do
      member do
        patch :transition
      end
      resources :comments, only: [ :create ]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
