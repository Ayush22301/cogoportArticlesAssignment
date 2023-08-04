# app/controllers/users_controller.rb
class UsersController < ApplicationController
    before_action :authenticate_user, only: [:profile, :my_posts, :follow_user,:addLike, :addComment, :recommendedPosts, :similarAuthorPosts]

    def create
        author = Author.find_or_create_by(name: user_params[:name]) # Create a new author based on the user's name
        @user = User.new(
          name: user_params[:name],
          email: user_params[:email],
          password: user_params[:password],
          author: author,
          following_ids: "",
          interests: user_params[:interests],
          specializations: user_params[:specializations]
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


  private
  
    def user_params
      params.permit(:name, :email, :password, :password_confirmation, :interests, :specializations)
    end
  end
  