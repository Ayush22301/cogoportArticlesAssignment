Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "articles#home"

  post "articles/create", to: "articles#create"

  put "articles/update", to: "articles#update"

  delete "articles/delete", to: "articles#delete"

  get "articles/filter", to: "articles#filter"

  get "articles/search", to: "articles#search"

  get "articles/sort", to: "articles#sort"

  get "articles/all", to: "articles#all"

  # put "articles/show", to: "articles#show"

  get "articles/topPosts", to: "articles#top_posts"



  ###user 

  resources :users, only: [:create]

  # User Login
  post '/login', to: 'sessions#create'

  # Profile
  get '/profile', to: 'users#profile'

  # My Posts
  get '/my_posts', to: 'users#my_posts'

  # follow_user
  post '/follow_user', to: 'users#follow_user'

  get '/show_author', to: 'users#show_author'
  
  put "/addLike", to: "users#addLike"

  put "/addComment", to:"users#addComment"

  get "/recommendedPosts", to: "users#recommendedPosts"

  get "/allTopics", to: "users#allTopics"

  get "/similarAuthorPosts", to: "users#similarAuthorPosts"

  put "/subscribewithoutpayment", to: "users#subscribewithoutpayment"

  put "/show", to: "users#show"

  get "/showDrafts", to: "users#showDrafts"

  post "/savelater", to: "users#savelater"

  get "/showsaved", to: "users#showsaved"

  post "/createlist", to: "users#createlist"

  get "/viewlistarticles", to: "users#viewlistarticles"

  get "/sharelist", to: "users#sharelist"
  ###revision history

  get "/revision_history", to: "revisions#revision_history"


  ###payment

  get '/payments', to: 'payments#payments_page'
  post '/subscribe', to: 'payments#subscribe'
  post '/payment_callback', to: 'payments#payment_callback'
  
end
