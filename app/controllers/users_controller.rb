# app/controllers/users_controller.rb
class UsersController < ApplicationController
    before_action :authenticate_user, only: [:profile, :my_posts, :follow_user,:addLike, :addComment, :recommendedPosts, :similarAuthorPosts, :subscribe, :show, :showDrafts]

    def create

      if User.exists?(name: user_params[:name]) || User.exists?(email: user_params[:email])
        render json: { error: 'Name or email already exists. Please choose a different name or email.' }, status: :unprocessable_entity
        return
      end
        author = Author.find_or_create_by(name: user_params[:name]) # Create a new author based on the user's name
        @user = User.new(
          name: user_params[:name],
          email: user_params[:email],
          password: user_params[:password],
          author: author,
          following_ids: "",
          interests: user_params[:interests],
          specializations: user_params[:specializations],
          expires_at: Time.now,
          last_viewed: Time.now
        )
    
        if @user.save
          token = JWT.encode({ user_id: @user.id }, Rails.application.secrets.secret_key_base, 'HS256')
          render json: { token: token, message: 'Registration successful. Please log in.' }, status: :created
        else
          render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end
  
    def profile
        render json: current_user, status: :ok
    end

    def my_posts
      author = current_user.author
      article_ids = author&.article_ids || [] 
      articles = []
      article_ids.each do |article_id|
        article = Article.find_by(id: article_id)
        # articles << article if article
        articles.push(article)
      end
      # articles = Article.all
      response = articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          views: article.views
        }
      end
        render json: response, status: :ok
    end

    def follow_user
      target_user_id = params[:id].to_i
      if current_user.follow_user(target_user_id)
        render json: current_user.following_ids
      else
        render json: { error: 'Failed to follow the user.' }, status: :unprocessable_entity
      end
    end

    def show_author
      author_username = params[:username]
      user = User.find_by(name: author_username)

    if user
      render json: user, status: :ok
    else
      render json: { error: 'User not found.' }, status: :not_found
    end
  end

  def addLike
      if current_user.id != params[:user_id].to_i
        render json: {error: 'Please login to like this artice.'}, status: :not_found
        return
      end

      article = Article.find_by(id: params[:article_id])


      if article.likes.include?(params[:user_id])
        render json: {error: 'You have already liked this article'}
        return
      end

      if article
        article.increment!(:no_of_likes)
        article.likes.push(params[:user_id])
        article.save
        response = {
          id: article.id,
          title: article.title,
          author: article.author,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          views: article.views
        }
  
        render json: response, status: :ok
      else
        render json: { error: 'Article not found' }, status: :not_found
      end
  end

  def addComment
    if current_user.id != params[:user_id].to_i
      render json: {error: 'Please login to like this artice.'}, status: :not_found
      return
    end
    
    article = Article.find_by(id: params[:article_id])

    if article
      article.increment!(:no_of_comments)
      article.comments.push({ user_id: params[:user_id], comment_text: params[:commentText] })
      article.save
      response = {
        id: article.id,
        title: article.title,
        author: article.author,
        description: article.description,
        genre: article.genre,
        image_url: article.image.attached? ? url_for(article.image) : nil,
        created_at: article.created_at,
        updated_at: article.updated_at,
        no_of_likes: article.no_of_likes,
        no_of_comments: article.no_of_comments,
        likes: article.likes,
        comments: article.comments,
        views: article.views
      }

      render json: response, status: :ok
    else
      render json: { error: 'Article not found' }, status: :not_found
    end 

  end

  def recommendedPosts
    interestsArray = current_user.interests.split(',')
    recommended_articles = Article.where(genre: interestsArray)
    response = recommended_articles.map do |article|
      {
        id: article.id,
        title: article.title,
        author: article.author,
        description: article.description,
        genre: article.genre,
        image_url: article.image.attached? ? url_for(article.image) : nil,
        created_at: article.created_at,
        updated_at: article.updated_at,
        no_of_likes: article.no_of_likes,
        no_of_comments: article.no_of_comments,
        likes: article.likes,
        comments: article.comments,
        views: article.views
      }
    end
    render json: response, status: :ok
  end

  def allTopics
    unique_genres = Article.distinct.pluck(:genre)
    render json: unique_genres
  end

  def similarAuthorPosts
    specArray = current_user.specializations.split(',')
    reqUsers = []
    reqUsers = User.select do |user|
      if user.specializations.nil?
        false
      else
        userspecArray = user.specializations.split(',')
        !(userspecArray & specArray).empty?
      end 
    end

    articles = []

    reqUsers.each do |user|
      author = user.author
      article_ids = author&.article_ids || []
      article_ids.each do |article_id|
        article = Article.find_by(id: article_id)
        articles.push(article)
      end
    end

    response = articles.map do |article|
      {
        id: article.id,
        title: article.title,
        author: article.author,
        description: article.description,
        genre: article.genre,
        image_url: article.image.attached? ? url_for(article.image) : nil,
        created_at: article.created_at,
        updated_at: article.updated_at,
        no_of_likes: article.no_of_likes,
        no_of_comments: article.no_of_comments,
        likes: article.likes,
        comments: article.comments,
        views: article.views
      }
    end
      render json: response, status: :ok
  end

  def subscribe
    subscription_plan = params[:subscription_plan]
    case subscription_plan
    when 'free'
      current_user.update(subscription_plan: 'free', remaining_posts: 1, expires_at: Time.now + 1.month)
    when '3_posts'
      # Implement payment logic using Razorpay API to charge $3
      #-----consider always done
      current_user.update(subscription_plan: '3_posts', remaining_posts: 3, expires_at: Time.now + 1.month)
    when '5_posts'
      # Implement payment logic using Razorpay API to charge $5
      current_user.update(subscription_plan: '5_posts', remaining_posts: 5, expires_at: Time.now + 1.month)
    when '10_posts'
      # Implement payment logic using Razorpay API to charge $10
      current_user.update(subscription_plan: '10_posts', remaining_posts: 10, expires_at: Time.now + 1.month)
    else
      render json: { error: 'Invalid subscription plan' }, status: :unprocessable_entity
      return
    end

    render json: { message: 'Subscription successful' , user: current_user }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # def reset_remaining_posts
  #   current_user.update(remaining_posts: current_user.subscription_plan.to_i)
  #   render json: { message: 'Remaining posts reset' }, status: :ok
  # end

  def show

    if !current_user
      render json: { error: 'Please login to view full Article' }
      return
    end

    article = Article.find_by(id: params[:id])

    if article

      crnt = Time.now

      if current_user.last_viewed.to_date != crnt.to_date
        current_user.update(remaining_posts: current_user.subscription_plan.to_i)
      end

      if current_user.expires_at < crnt
        current_user.update(subscription_plan: 'free', remaining_posts: 1, expires_at: (crnt + 1.month))
      end

      if current_user.remaining_posts == 0
        render json: { error: 'Your daily limit of viewing posts is reached. Please try tomorrow or upgrade to higher plan' }
        return
      end
      

      # current_user.save

      current_user.update(last_viewed: crnt)
      current_user.decrement!(:remaining_posts)

      current_user.save
      
      article.increment!(:views)

      article.save

      response = {
        id: article.id,
        title: article.title,
        author: article.author,
        description: article.description,
        genre: article.genre,
        image_url: article.image.attached? ? url_for(article.image) : nil,
        created_at: article.created_at,
        updated_at: article.updated_at,
        no_of_likes: article.no_of_likes,
        no_of_comments: article.no_of_comments,
        likes: article.likes,
        comments: article.comments,
        views: article.views,
        rem: current_user.remaining_posts
      }

      render json: response, status: :ok
    else
      render json: { error: 'Article not found' }, status: :not_found
    end

  end

  def showDrafts
    author = current_user.author
      article_ids = author&.article_ids || [] 
      articles = []
      article_ids.each do |article_id|
        article = Article.find_by(id: article_id)
        if article.isDraft
          articles.push(article)
        end
      end
      # articles = Article.all
      response = articles.map do |article|
        {
          id: article.id,
          title: article.title,
          author: article.author,
          description: article.description,
          genre: article.genre,
          image_url: article.image.attached? ? url_for(article.image) : nil,
          created_at: article.created_at,
          updated_at: article.updated_at,
          no_of_likes: article.no_of_likes,
          no_of_comments: article.no_of_comments,
          likes: article.likes,
          comments: article.comments,
          views: article.views
        }
      end
        render json: response, status: :ok
  end

  private
  
    def user_params
      params.permit(:name, :email, :password, :password_confirmation, :interests, :specializations)
    end
  end
  